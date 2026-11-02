package com.example.saber_plus

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class PrivateOfflineLeaseTest {
    @Test fun beginsWith72Hours() = assertEquals(PRIVATE_WINDOW_MS, privateLeaseRemaining(500, "b", "b", 500))
    @Test fun expiresAtExactBoundary() = assertNull(privateLeaseRemaining(500, "b", "b", 500 + PRIVATE_WINDOW_MS))
    @Test fun lastMillisecondIsBounded() = assertEquals(1L, privateLeaseRemaining(500, "b", "b", 499 + PRIVATE_WINDOW_MS))
    @Test fun rebootFailsClosed() = assertNull(privateLeaseRemaining(500, "b", "next", 1000))
    @Test fun elapsedRollbackFailsClosed() = assertNull(privateLeaseRemaining(500, "b", "b", 499))
    @Test fun negativeAnchorFailsClosed() = assertNull(privateLeaseRemaining(-1, "b", "b", 0))
    @Test fun longUptimeCannotOverflow() = assertNull(privateLeaseRemaining(0, "b", "b", Long.MAX_VALUE))
}
