package com.example.saber_plus

internal const val PRIVATE_WINDOW_MS = 72L * 60 * 60 * 1000

/** Only boot identity and elapsedRealtime; wall clock is deliberately not an input. */
internal fun privateLeaseRemaining(anchor: Long, boot: String, currentBoot: String, elapsed: Long): Long? {
    if (boot != currentBoot || anchor < 0 || elapsed < anchor) return null
    val age = elapsed - anchor
    if (age >= PRIVATE_WINDOW_MS) return null
    return PRIVATE_WINDOW_MS - age
}
