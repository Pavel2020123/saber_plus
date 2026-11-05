package com.example.saber_plus

import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.io.InterruptedIOException
import java.io.OutputStream
import java.util.concurrent.atomic.AtomicInteger

internal const val PRIVATE_DOCUMENT_LIMIT = 5 * 1024 * 1024
internal class PrivateDocumentTooLarge : java.io.IOException("Private document exceeds limit")

/** Never trusts a provider's declared size, and never reads an entire oversized source. */
internal fun readPrivateDocument(
    source: InputStream,
    declaredSize: Long = -1,
    current: () -> Boolean = { true },
): ByteArray {
    if (declaredSize > PRIVATE_DOCUMENT_LIMIT) throw PrivateDocumentTooLarge()
    val output = ByteArrayOutputStream()
    val buffer = ByteArray(8192)
    var emptyReads = 0
    while (true) {
        if (!current() || Thread.currentThread().isInterrupted) throw InterruptedIOException()
        val count = source.read(buffer, 0, minOf(buffer.size, PRIVATE_DOCUMENT_LIMIT - output.size() + 1))
        if (count == -1) break
        if (count == 0) {
            if (++emptyReads > 8) throw java.io.IOException("Provider made no progress")
            continue
        }
        emptyReads = 0
        if (count > PRIVATE_DOCUMENT_LIMIT - output.size()) throw PrivateDocumentTooLarge()
        output.write(buffer, 0, count)
    }
    if (!current()) throw InterruptedIOException()
    if (output.size() == 0) throw java.io.IOException("Empty private document")
    return output.toByteArray()
}

internal fun validatePrivateExport(bytes: ByteArray, mime: String) {
    if (bytes.isEmpty() || bytes.size > PRIVATE_DOCUMENT_LIMIT) throw PrivateDocumentTooLarge()
    val pdf = bytes.size >= 5 && String(bytes, 0, 5, Charsets.US_ASCII) == "%PDF-"
    val webp = bytes.size >= 12 && String(bytes, 0, 4, Charsets.US_ASCII) == "RIFF" &&
        String(bytes, 8, 4, Charsets.US_ASCII) == "WEBP"
    require((mime == "application/pdf" && pdf) || (mime == "image/webp" && webp))
}

internal fun writePrivateDocument(bytes: ByteArray, output: OutputStream, current: () -> Boolean) {
    if (bytes.isEmpty() || bytes.size > PRIVATE_DOCUMENT_LIMIT) throw PrivateDocumentTooLarge()
    var offset = 0
    while (offset < bytes.size) {
        if (!current() || Thread.currentThread().isInterrupted) throw InterruptedIOException()
        val count = minOf(8192, bytes.size - offset)
        output.write(bytes, offset, count)
        offset += count
    }
    if (!current()) throw InterruptedIOException()
    output.flush()
}

internal data class PrivateDocumentTicket(val operation: String, val requestCode: Int, val exporting: Boolean)

/** No activity request code is reused in this process, even after cancellation/rotation. */
internal class PrivateDocumentGate(private val nextCode: () -> Int = { codes.getAndIncrement() }) {
    companion object { private val codes = AtomicInteger(0x5300) }
    private val issued = mutableSetOf<Int>()
    private val operations = mutableSetOf<String>()
    @Volatile private var active: PrivateDocumentTicket? = null
    private var closed = false
    fun start(operation: String, exporting: Boolean): PrivateDocumentTicket {
        check(!closed && active == null)
        require(Regex("^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-4[a-fA-F0-9]{3}-[89abAB][a-fA-F0-9]{3}-[a-fA-F0-9]{12}$").matches(operation))
        require(operation !in operations)
        val code = nextCode()
        check(code in 0x5300..0x7fff && code !in issued)
        val ticket = PrivateDocumentTicket(operation, code, exporting)
        issued.add(code); operations.add(operation); active = ticket
        return ticket
    }
    fun current(ticket: PrivateDocumentTicket) = active === ticket
    fun owns(code: Int) = code in issued
    fun finish(ticket: PrivateDocumentTicket): Boolean {
        if (!current(ticket)) return false
        active = null
        return true
    }
    fun cancel(operation: String): Boolean {
        if (active?.operation != operation) return false
        active = null
        return true
    }
    fun close() { active = null; closed = true }
}
