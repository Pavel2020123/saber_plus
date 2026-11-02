package com.example.saber_plus

import android.app.Activity
import android.os.SystemClock
import android.net.ConnectivityManager
import android.net.Network
import android.provider.Settings
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.AtomicFile
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File
import java.security.KeyStore
import java.security.MessageDigest
import java.util.concurrent.Executors
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** App-private, no-backup authenticated ciphertext. Never touches exported PDFs. */
class PrivateOfflineVault(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "saberplus/private_offline_v1")
    private val executor = Executors.newSingleThreadExecutor()
    private val root = File(activity.noBackupFilesDir, "private_offline_v1")
    private val maxPayload = 4 * 1024 * 1024
    private val connectivity = activity.getSystemService(ConnectivityManager::class.java)
    private val networkCallback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) {
            activity.runOnUiThread { channel.invokeMethod("networkAvailable", null) }
        }
    }

    init {
        connectivity.registerDefaultNetworkCallback(networkCallback)
        channel.setMethodCallHandler { call, result ->
            executor.execute {
                try {
                    val value = handle(call)
                    activity.runOnUiThread { result.success(value) }
                } catch (_: Exception) {
                    activity.runOnUiThread {
                        result.error("PRIVATE_CACHE_UNAVAILABLE", "Revalida el contenido privado con conexión.", null)
                    }
                }
            }
        }
    }

    private fun digest(value: String) = MessageDigest.getInstance("SHA-256")
        .digest(value.toByteArray(Charsets.UTF_8)).joinToString("") { "%02x".format(it) }

    private fun id(call: MethodCall, key: String): String {
        val value = call.argument<String>(key) ?: error("Missing identity")
        require(value.length in 1..128 && value.matches(Regex("[a-zA-Z0-9_-]+")))
        return value
    }

    private fun bootId(): String {
        val count = Settings.Global.getInt(activity.contentResolver, Settings.Global.BOOT_COUNT, -1)
        require(count >= 0)
        return count.toString()
    }

    private fun keys() = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
    private fun alias(owner: String) = "saberplus.private.offline.v1.${digest(owner)}"
    private fun key(owner: String, create: Boolean): SecretKey {
        val existing = keys().getKey(alias(owner), null)
        if (existing is SecretKey) return existing
        check(create)
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").apply {
            init(KeyGenParameterSpec.Builder(alias(owner), KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setKeySize(256).setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setRandomizedEncryptionRequired(true).build())
        }.generateKey()
    }

    private fun file(owner: String, context: String): AtomicFile {
        check(root.isDirectory || root.mkdirs())
        return AtomicFile(File(root, "${digest(owner)}_${digest(context)}.bin"))
    }

    private fun handle(call: MethodCall): Any? {
        if (call.method == "clock") return mapOf("bootId" to bootId(), "elapsedMs" to SystemClock.elapsedRealtime())
        val owner = id(call, "ownerId")
        if (call.method == "clearAccount") {
            // Key deletion also makes any ciphertext left by a failed cleanup unreadable.
            keys().deleteEntry(alias(owner))
            root.listFiles()?.filter { it.name.startsWith("${digest(owner)}_") }?.forEach { it.delete() }
            return null
        }
        val context = id(call, "contextId")
        val target = file(owner, context)
        val aad = "$owner\u0000$context".toByteArray(Charsets.UTF_8)
        when (call.method) {
            "clearContext" -> { target.delete(); return null }
            "seal" -> {
                val payload = call.argument<String>("payload") ?: error("Missing payload")
                require(payload.toByteArray(Charsets.UTF_8).size <= maxPayload)
                val anchor = call.argument<Number>("anchorMs")?.toLong() ?: error("Missing anchor")
                val boot = call.argument<String>("bootId") ?: error("Missing boot")
                val now = SystemClock.elapsedRealtime()
                require(privateLeaseRemaining(anchor, boot, bootId(), now) != null)
                val envelope = JSONObject().put("v", 1).put("owner", owner).put("context", context)
                    .put("boot", boot).put("anchor", anchor).put("payload", payload).toString().toByteArray(Charsets.UTF_8)
                val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                cipher.init(Cipher.ENCRYPT_MODE, key(owner, true))
                cipher.updateAAD(aad)
                val encrypted = cipher.iv + cipher.doFinal(envelope)
                // Bounded private storage; never evict or inspect exported PDFs.
                val others = root.listFiles()?.filter { it.name.endsWith(".bin") && it != target.baseFile } ?: emptyList()
                require(others.size < 32 && others.sumOf { it.length() } + encrypted.size <= 64L * 1024 * 1024)
                val output = target.startWrite()
                try { output.write(encrypted); target.finishWrite(output) }
                catch (error: Exception) { target.failWrite(output); throw error }
                return null
            }
            "read" -> {
                if (!target.baseFile.exists()) return null
                require(target.baseFile.length() in 29..(maxPayload + 8192).toLong())
                val input = target.readFully()
                val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                cipher.init(Cipher.DECRYPT_MODE, key(owner, false), GCMParameterSpec(128, input.copyOfRange(0, 12)))
                cipher.updateAAD(aad)
                val envelope = JSONObject(String(cipher.doFinal(input.copyOfRange(12, input.size)), Charsets.UTF_8))
                require(envelope.getInt("v") == 1 && envelope.getString("owner") == owner && envelope.getString("context") == context)
                val anchor = envelope.getLong("anchor")
                val now = SystemClock.elapsedRealtime()
                val remaining = privateLeaseRemaining(anchor, envelope.getString("boot"), bootId(), now)
                if (remaining == null) {
                    target.delete()
                    return null
                }
                return mapOf("payload" to envelope.getString("payload"), "remainingMs" to remaining)
            }
            else -> error("Unsupported private cache method")
        }
    }

    fun close() {
        connectivity.unregisterNetworkCallback(networkCallback)
        channel.setMethodCallHandler(null)
        executor.shutdown()
    }
}
