package com.example.saber_plus

import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.io.InterruptedIOException
import org.junit.Assert.*
import org.junit.Test

class PrivateDocumentBytesTest {
    private val first = "2df4f385-fec2-4cb1-89af-91f67a476b52"
    private val second = "3df4f385-fec2-4cb1-89af-91f67a476b52"
    @Test fun acceptsExactLimitAndUnknownSize() {
        val bytes = ByteArray(PRIVATE_DOCUMENT_LIMIT) { 7 }
        assertArrayEquals(bytes, readPrivateDocument(ByteArrayInputStream(bytes)))
    }
    @Test fun declaredOversizeDoesNotReadSource() {
        val source = object : InputStream() { override fun read(): Int = fail("Must not read oversized source").let { -1 } }
        assertThrows(PrivateDocumentTooLarge::class.java) { readPrivateDocument(source, Long.MAX_VALUE) }
    }
    @Test fun dishonestSizeCannotBypassStreamingLimit() {
        var read = 0
        val source = object : InputStream() {
            override fun read(): Int { read++; return 1 }
            override fun read(b: ByteArray, off: Int, len: Int): Int { read += len; return len }
        }
        assertThrows(PrivateDocumentTooLarge::class.java) { readPrivateDocument(source, 1) }
        assertEquals(PRIVATE_DOCUMENT_LIMIT + 1, read)
    }
    @Test fun emptyAndNonProgressingProvidersFail() {
        assertThrows(java.io.IOException::class.java) { readPrivateDocument(ByteArrayInputStream(byteArrayOf())) }
        val source = object : InputStream() { override fun read() = 0; override fun read(b: ByteArray, off: Int, len: Int) = 0 }
        assertThrows(java.io.IOException::class.java) { readPrivateDocument(source) }
    }
    @Test fun cancellationStopsReadingBeforeNextChunk() {
        var current = true
        val source = object : InputStream() {
            override fun read() = -1
            override fun read(b: ByteArray, off: Int, len: Int): Int { current = false; return 1 }
        }
        assertThrows(InterruptedIOException::class.java) { readPrivateDocument(source, current = { current }) }
    }
    @Test fun exportOnlyAdmitsBoundedPdfOrWebpEnvelopes() {
        validatePrivateExport("%PDF-1.7\n%%EOF".toByteArray(), "application/pdf")
        validatePrivateExport("RIFF0000WEBP".toByteArray(), "image/webp")
        assertThrows(IllegalArgumentException::class.java) { validatePrivateExport("<html>".toByteArray(), "application/pdf") }
        assertThrows(IllegalArgumentException::class.java) { validatePrivateExport("%PDF-".toByteArray(), "text/html") }
        assertThrows(PrivateDocumentTooLarge::class.java) { validatePrivateExport(ByteArray(PRIVATE_DOCUMENT_LIMIT + 1), "application/pdf") }
    }
    @Test fun writesExactBytesWithoutChangingInput() {
        val bytes = ByteArray(20000) { 8 }; val output = ByteArrayOutputStream()
        writePrivateDocument(bytes, output) { true }
        assertArrayEquals(bytes, output.toByteArray())
    }
    @Test fun cancellationCannotClaimFullExport() {
        var current = true; var count = 0
        val output = object : ByteArrayOutputStream() {
            override fun write(b: ByteArray, off: Int, len: Int) { super.write(b, off, len); count += len; current = false }
        }
        assertThrows(InterruptedIOException::class.java) { writePrivateDocument(ByteArray(20000), output) { current } }
        assertEquals(8192, count)
    }
    @Test fun busyAndWrongCancellationNeverAffectCurrentOwner() {
        var code = 0x5300; val gate = PrivateDocumentGate { code++ }
        val active = gate.start(first, false)
        assertThrows(IllegalStateException::class.java) { gate.start(second, true) }
        assertFalse(gate.cancel(second)); assertTrue(gate.current(active))
    }
    @Test fun lateResultCannotFinishAReplacementOperation() {
        var code = 0x5300; val gate = PrivateDocumentGate { code++ }
        val old = gate.start(first, false); assertTrue(gate.cancel(first))
        val next = gate.start(second, true)
        assertNotEquals(old.requestCode, next.requestCode)
        assertTrue(gate.owns(old.requestCode)); assertFalse(gate.finish(old)); assertTrue(gate.current(next))
        assertTrue(gate.finish(next)); assertFalse(gate.finish(next))
    }
    @Test fun refusesReusedTokensExhaustedCodesAndClosedGate() {
        val gate = PrivateDocumentGate { 0x5300 }; val old = gate.start(first, false); gate.finish(old)
        assertThrows(IllegalArgumentException::class.java) { gate.start(first, false) }
        assertThrows(IllegalStateException::class.java) { gate.start(second, false) }
        val exhausted = PrivateDocumentGate { 0x8000 }
        assertThrows(IllegalStateException::class.java) { exhausted.start(first, false) }
        gate.close(); assertThrows(IllegalStateException::class.java) { gate.start(second, false) }
    }
}
