package com.example.saber_plus

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.Closeable
import java.util.concurrent.Future
import java.util.concurrent.SynchronousQueue
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/** Local-debug C5 bridge. No broad storage permission, persistent URI grant or file cache. */
class PrivateDocumentsPlugin : FlutterPlugin, ActivityAware, PluginRegistry.ActivityResultListener {
    private lateinit var context: Context
    private lateinit var channel: MethodChannel
    private var binding: ActivityPluginBinding? = null
    private val main = Handler(Looper.getMainLooper())
    private val gate = PrivateDocumentGate()
    // No queue: an uncooperative provider cannot accumulate jobs or selected payloads.
    private val io = ThreadPoolExecutor(1, 1, 0, TimeUnit.MILLISECONDS, SynchronousQueue<Runnable>(),
        { task -> Thread(task, "saberplus-private-document").apply { isDaemon = true } })
    private class Pending(val ticket: PrivateDocumentTicket, val result: MethodChannel.Result,
                          var bytes: ByteArray? = null, val mime: String? = null) {
        val cancellation = CancellationSignal()
        val resource = AtomicReference<Closeable?>()
        var future: Future<*>? = null
        var timeout: Runnable? = null
        var selected = false
    }
    private var pending: Pending? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "saberplus/private_documents_v1")
        channel.setMethodCallHandler(::call)
    }
    private fun call(call: MethodCall, result: MethodChannel.Result) {
        if (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE == 0) {
            result.error("DOCUMENT_DISABLED", "Private documents require a local debug installation.", null); return
        }
        val args = call.arguments as? Map<*, *>
        val operation = args?.get("operationId") as? String
        if (args == null || operation == null || args.keys.any { it !in setOf("operationId", "bytes", "mime") }) {
            result.error("DOCUMENT_INVALID", "Invalid private document request.", null); return
        }
        if (call.method == "cancel") {
            if (args.size != 1) { result.error("DOCUMENT_INVALID", "Invalid cancellation.", null); return }
            val p = pending
            if (p != null && p.ticket.operation == operation) {
                abort(p); result.success(true)
            } else result.success(false)
            return
        }
        if (call.method !in setOf("pick", "pickImage", "export")) { result.notImplemented(); return }
        val activity = binding?.activity
        if (activity == null || activity.isFinishing) { result.error("DOCUMENT_UNAVAILABLE", "Activity unavailable.", null); return }
        if (pending != null || io.activeCount > 0) { result.error("DOCUMENT_BUSY", "A document operation is still active.", null); return }
        val exporting = call.method == "export"
        val bytes = args["bytes"] as? ByteArray
        val mime = args["mime"] as? String
        try {
            if (exporting) {
                require(args.size == 3 && bytes != null && mime != null)
                validatePrivateExport(bytes, mime)
            } else require(args.size == 1)
            val ticket = gate.start(operation, exporting)
            val p = Pending(ticket, result, if (exporting) bytes?.clone() else null, mime)
            pending = p
            val intent = if (exporting) Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = mime
                putExtra(Intent.EXTRA_TITLE, if (mime == "application/pdf") "Documento-SaberPlus.pdf" else "Documento-SaberPlus.webp")
                addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            } else Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = if (call.method == "pickImage") "image/*" else "*/*"
                putExtra(Intent.EXTRA_MIME_TYPES, if (call.method == "pickImage")
                    arrayOf("image/png", "image/jpeg", "image/webp") else
                    arrayOf("application/pdf", "image/png", "image/jpeg", "image/webp"))
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            try { activity.startActivityForResult(intent, ticket.requestCode) }
            catch (_: Exception) { finish(p, "DOCUMENT_UNAVAILABLE") }
        } catch (_: PrivateDocumentTooLarge) { result.error("DOCUMENT_TOO_LARGE", "Select a document up to 5 MiB.", null) }
        catch (_: Exception) { result.error("DOCUMENT_INVALID", "Invalid private document request.", null) }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (!gate.owns(requestCode)) return false
        val p = pending
        if (p == null || p.ticket.requestCode != requestCode || p.selected) return true
        if (resultCode == Activity.RESULT_CANCELED) {
            finish(p, value = if (p.ticket.exporting) false else null); return true
        }
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri?.scheme != "content" || uri.authority.isNullOrBlank() ||
            (data?.clipData?.itemCount ?: 0) > 1) {
            finish(p, if (p.ticket.exporting) "DOCUMENT_EXPORT_UNCONFIRMED" else "DOCUMENT_UNAVAILABLE"); return true
        }
        p.selected = true
        p.timeout = Runnable { if (gate.current(p.ticket)) abort(p) }
        main.postDelayed(p.timeout!!, 30000)
        try {
            p.future = io.submit {
                try {
                    val value: Any = if (p.ticket.exporting) { export(p, uri); true } else read(p, uri)
                    main.post { finish(p, value = value) }
                } catch (_: PrivateDocumentTooLarge) { main.post { finish(p, "DOCUMENT_TOO_LARGE") } }
                catch (_: Exception) { main.post { finish(p, if (p.ticket.exporting) "DOCUMENT_EXPORT_UNCONFIRMED" else "DOCUMENT_UNAVAILABLE") } }
                finally { p.bytes = null }
            }
        } catch (_: Exception) { finish(p, if (p.ticket.exporting) "DOCUMENT_EXPORT_UNCONFIRMED" else "DOCUMENT_UNAVAILABLE") }
        return true
    }
    private fun read(p: Pending, uri: Uri): ByteArray {
        var declared = -1L
        context.contentResolver.query(uri, arrayOf(OpenableColumns.SIZE), null, null, null, p.cancellation)?.use { cursor ->
            val index = cursor.getColumnIndex(OpenableColumns.SIZE)
            if (index >= 0 && cursor.moveToFirst() && !cursor.isNull(index)) declared = cursor.getLong(index)
        }
        if (declared > PRIVATE_DOCUMENT_LIMIT) throw PrivateDocumentTooLarge()
        return context.contentResolver.openAssetFileDescriptor(uri, "r", p.cancellation)?.use { descriptor ->
            if (descriptor.declaredLength > PRIVATE_DOCUMENT_LIMIT) throw PrivateDocumentTooLarge()
            descriptor.createInputStream().use { stream ->
                p.resource.set(stream)
                try { readPrivateDocument(stream, declared) { gate.current(p.ticket) } }
                finally { p.resource.compareAndSet(stream, null) }
            }
        } ?: throw java.io.IOException("Document unavailable")
    }
    private fun export(p: Pending, uri: Uri) {
        val bytes = p.bytes ?: throw java.io.InterruptedIOException()
        if (!gate.current(p.ticket)) throw java.io.InterruptedIOException()
        context.contentResolver.openAssetFileDescriptor(uri, "w", p.cancellation)?.use { descriptor ->
            descriptor.createOutputStream().use { stream ->
                p.resource.set(stream)
                try { writePrivateDocument(bytes, stream) { gate.current(p.ticket) } }
                finally { p.resource.compareAndSet(stream, null) }
            }
        } ?: throw java.io.IOException("Destination unavailable")
    }
    private fun finish(p: Pending, error: String? = null, value: Any? = null) {
        if (!gate.finish(p.ticket)) return
        if (pending === p) pending = null
        p.timeout?.let { main.removeCallbacks(it) }
        p.bytes = null
        if (error == null) p.result.success(value)
        else p.result.error(error, if (p.ticket.exporting) "Export not confirmed; check the chosen destination." else "Private document not available.", null)
    }
    private fun abort(p: Pending) {
        // Export may already be partial or complete. Never claim cancellation
        // erased it and never delete a user-selected URI to hide the failure.
        if (!gate.cancel(p.ticket.operation)) return
        if (pending === p) pending = null
        p.timeout?.let { main.removeCallbacks(it) }
        runCatching { p.cancellation.cancel() }; p.future?.cancel(true); p.bytes = null
        p.resource.getAndSet(null)?.let { resource ->
            Thread({ runCatching { resource.close() } }, "saberplus-document-close").apply { isDaemon = true; start() }
        }
        p.result.error(if (p.ticket.exporting && p.selected) "DOCUMENT_EXPORT_UNCONFIRMED" else "DOCUMENT_CANCELLED", "Private document operation ended; verify any chosen export destination.", null)
    }
    override fun onAttachedToActivity(binding: ActivityPluginBinding) { this.binding = binding; binding.addActivityResultListener(this) }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = onAttachedToActivity(binding)
    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()
    override fun onDetachedFromActivity() {
        binding?.removeActivityResultListener(this); binding = null
        pending?.let { abort(it) }
    }
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        onDetachedFromActivity(); gate.close(); io.shutdownNow(); channel.setMethodCallHandler(null)
    }
}
