package com.localbridge.localbridge.presentation.controller;

import com.localbridge.localbridge.presentation.dto.ApiResponse;
import com.localbridge.localbridge.presentation.dto.UpdateStatusDto;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.aot.hint.annotation.RegisterReflectionForBinding;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;
import java.util.Map;

@RestController
@RequestMapping("/api/update")
@CrossOrigin(origins = "*")
public class UpdateController {

    @Value("${app.version:v0.0.0-dev}")
    private String currentVersion;

    private static final String GITHUB_REPO = "jecem-ben-slama/LocalBridge";
    private static final String GITHUB_API_URL = "https://api.github.com/repos/" + GITHUB_REPO + "/releases/latest";

    @GetMapping("/check")
    @RegisterReflectionForBinding(UpdateStatusDto.class)
    public ResponseEntity<ApiResponse<UpdateStatusDto>> checkUpdate() {
        UpdateStatusDto status = new UpdateStatusDto();
        status.setCurrentVersion(currentVersion);
        status.setUpdateAvailable(false);

        try {
            RestTemplate restTemplate = new RestTemplate();
            HttpHeaders headers = new HttpHeaders();
            headers.set("User-Agent", "LocalBridge-App");
            headers.set("Accept", "application/vnd.github.v3+json");

            ResponseEntity<Map> response = restTemplate.exchange(
                    GITHUB_API_URL,
                    HttpMethod.GET,
                    new HttpEntity<>(headers),
                    Map.class);

            if (response.getBody() != null) {
                String latestTag = (String) response.getBody().get("tag_name");
                String releaseUrl = (String) response.getBody().get("html_url");

                status.setLatestVersion(latestTag);
                status.setReleaseUrl(releaseUrl);

                if (latestTag != null && !latestTag.trim().equalsIgnoreCase(currentVersion.trim())) {
                    status.setUpdateAvailable(true);
                }
            }

            return ResponseEntity.ok(ApiResponse.success("Update check completed", status));
        } catch (Exception e) {
            // Degrade gracefully if offline or rate-limited
            status.setLatestVersion(currentVersion);
            return ResponseEntity.ok(ApiResponse.success("Unable to check for updates online", status));
        }
    }

    // Response DTO
 }