package ng.gofinancials.gt_device_integrity

import android.content.Context
import android.util.Base64
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.IntegrityServiceException
import com.google.android.play.core.integrity.IntegrityTokenRequest
import com.google.android.play.core.integrity.StandardIntegrityException
import com.google.android.play.core.integrity.StandardIntegrityManager.PrepareIntegrityTokenRequest
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenProvider
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenRequest
import com.google.android.play.core.integrity.model.IntegrityErrorCode
import com.google.android.play.core.integrity.model.StandardIntegrityErrorCode
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

/**
 * Produces Play Integrity tokens. Every answer is a map with a `status` of
 * `ready`, `token`, `unavailable` or `failed`; verifying a token is the
 * backend's job.
 *
 * Classic requests (nonce) back `attest`; standard requests (request hash)
 * back `attestationToken`. Both bind to the URL-safe, padded base64 of the
 * SHA-256 of the value Dart passes, which the server reproduces.
 */
internal class PlayIntegrityAttestation(private val context: Context) {
    private var provider: StandardIntegrityTokenProvider? = null
    private var providerProjectNumber: Long? = null

    fun prepare(projectNumber: Long?, result: MethodChannel.Result) {
        withProvider(projectNumber, result) { result.success(mapOf("status" to "ready")) }
    }

    fun attest(challenge: String?, projectNumber: Long?, result: MethodChannel.Result) {
        if (challenge == null) return result.success(failed("invalid_arguments"))

        val builder = IntegrityTokenRequest.builder().setNonce(sha256(challenge))

        if (projectNumber != null) builder.setCloudProjectNumber(projectNumber)

        val manager = IntegrityManagerFactory.create(context)
        val request = manager.requestIntegrityToken(builder.build())

        request.addOnSuccessListener { result.success(token(it.token())) }
        request.addOnFailureListener { result.success(classicProblem(it)) }
    }

    fun token(data: String?, projectNumber: Long?, result: MethodChannel.Result) {
        if (data == null) return result.success(failed("invalid_arguments"))

        val requestHash = sha256(data)

        withProvider(projectNumber, result) { request(it, requestHash, projectNumber, true, result) }
    }

    private fun request(
        current: StandardIntegrityTokenProvider,
        requestHash: String,
        projectNumber: Long?,
        canRetry: Boolean,
        result: MethodChannel.Result,
    ) {
        val tokenRequest = StandardIntegrityTokenRequest.builder().setRequestHash(requestHash).build()
        val task = current.request(tokenRequest)

        task.addOnSuccessListener { result.success(token(it.token())) }
        task.addOnFailureListener { error ->
            val code = (error as? StandardIntegrityException)?.errorCode
            val isProviderInvalid = code == StandardIntegrityErrorCode.INTEGRITY_TOKEN_PROVIDER_INVALID

            val shouldRetry = isProviderInvalid && canRetry

            if (!shouldRetry) {
                result.success(standardProblem(error))
                return@addOnFailureListener
            }

            provider = null
            withProvider(projectNumber, result) { request(it, requestHash, projectNumber, false, result) }
        }
    }

    /** Runs [onReady] with a prepared provider, preparing one when there is none for [projectNumber]. */
    private fun withProvider(
        projectNumber: Long?,
        result: MethodChannel.Result,
        onReady: (StandardIntegrityTokenProvider) -> Unit,
    ) {
        if (projectNumber == null) return result.success(failed("cloud_project_number_required"))

        val cached = provider
        val isSameProject = providerProjectNumber == projectNumber

        if (cached != null && isSameProject) return onReady(cached)

        val manager = IntegrityManagerFactory.createStandard(context)
        val prepareRequest = PrepareIntegrityTokenRequest.builder().setCloudProjectNumber(projectNumber).build()
        val task = manager.prepareIntegrityToken(prepareRequest)

        task.addOnSuccessListener {
            provider = it
            providerProjectNumber = projectNumber
            onReady(it)
        }
        task.addOnFailureListener { result.success(standardProblem(it)) }
    }

    private fun classicProblem(error: Exception): Map<String, Any?> {
        val code = (error as? IntegrityServiceException)?.errorCode

        return problem(code, CLASSIC_UNAVAILABLE, CLASSIC_FAILED)
    }

    private fun standardProblem(error: Exception): Map<String, Any?> {
        val code = (error as? StandardIntegrityException)?.errorCode

        return problem(code, STANDARD_UNAVAILABLE, STANDARD_FAILED)
    }

    private fun problem(code: Int?, unavailable: Map<Int, String>, failed: Map<Int, String>): Map<String, Any?> {
        val unavailableReason = unavailable[code]
        val status = if (unavailableReason != null) "unavailable" else "failed"
        val reason = unavailableReason ?: failed[code] ?: "play_integrity_error"

        return mapOf("status" to status, "reason" to reason, "code" to code)
    }

    private fun token(token: String): Map<String, Any?> {
        return mapOf("status" to "token", "platform" to "android", "token" to token)
    }

    private fun failed(reason: String): Map<String, Any?> {
        return mapOf("status" to "failed", "reason" to reason)
    }

    private fun sha256(value: String): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(value.toByteArray(Charsets.UTF_8))
        val flags = Base64.URL_SAFE or Base64.NO_WRAP

        return Base64.encodeToString(digest, flags)
    }

    private companion object {
        val CLASSIC_UNAVAILABLE = mapOf(
            IntegrityErrorCode.API_NOT_AVAILABLE to "api_not_available",
            IntegrityErrorCode.PLAY_STORE_NOT_FOUND to "play_store_not_found",
            IntegrityErrorCode.PLAY_SERVICES_NOT_FOUND to "play_services_not_found",
            IntegrityErrorCode.PLAY_STORE_VERSION_OUTDATED to "play_store_outdated",
            IntegrityErrorCode.PLAY_SERVICES_VERSION_OUTDATED to "play_services_outdated",
        )

        val CLASSIC_FAILED = mapOf(
            IntegrityErrorCode.NETWORK_ERROR to "network_error",
            IntegrityErrorCode.TOO_MANY_REQUESTS to "too_many_requests",
            IntegrityErrorCode.GOOGLE_SERVER_UNAVAILABLE to "server_unavailable",
            IntegrityErrorCode.CLIENT_TRANSIENT_ERROR to "transient_error",
        )

        val STANDARD_UNAVAILABLE = mapOf(
            StandardIntegrityErrorCode.API_NOT_AVAILABLE to "api_not_available",
            StandardIntegrityErrorCode.PLAY_STORE_NOT_FOUND to "play_store_not_found",
            StandardIntegrityErrorCode.PLAY_SERVICES_NOT_FOUND to "play_services_not_found",
            StandardIntegrityErrorCode.PLAY_STORE_VERSION_OUTDATED to "play_store_outdated",
            StandardIntegrityErrorCode.PLAY_SERVICES_VERSION_OUTDATED to "play_services_outdated",
        )

        val STANDARD_FAILED = mapOf(
            StandardIntegrityErrorCode.NETWORK_ERROR to "network_error",
            StandardIntegrityErrorCode.TOO_MANY_REQUESTS to "too_many_requests",
            StandardIntegrityErrorCode.GOOGLE_SERVER_UNAVAILABLE to "server_unavailable",
            StandardIntegrityErrorCode.CLIENT_TRANSIENT_ERROR to "transient_error",
        )
    }
}
