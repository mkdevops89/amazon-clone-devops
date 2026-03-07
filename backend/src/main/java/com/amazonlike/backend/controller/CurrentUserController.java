package com.amazonlike.backend.controller;

import com.amazonlike.backend.model.ERole;
import com.amazonlike.backend.model.Role;
import com.amazonlike.backend.model.User;
import com.amazonlike.backend.repository.RoleRepository;
import com.amazonlike.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping({ "/api/auth", "/auth" })
public class CurrentUserController {

    @Autowired
    UserRepository userRepository;

    @Autowired
    RoleRepository roleRepository;

    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser(@AuthenticationPrincipal Jwt jwt) {
        if (jwt == null) {
            return ResponseEntity.status(401).body("Error: Unauthorized");
        }

        // Cognito stores the unique ID in the 'sub' claim and the email in the 'email'
        // claim
        String cognitoSub = jwt.getClaimAsString("sub");
        String email = jwt.getClaimAsString("email");

        // 1. Check if we already have this Cognito User in our local database
        Optional<User> optionalUser = userRepository.findByCognitoSub(cognitoSub);

        User user;
        if (optionalUser.isPresent()) {
            user = optionalUser.get();
        } else {
            // 2. First-time login! Auto-register the Cognito User into our local MySQL
            // ecosystem.
            // Note: We use the email prefix as the username for backwards compatibility.
            String fallbackUsername = email != null ? email.split("@")[0] : "user_" + cognitoSub.substring(0, 5);

            user = new User(fallbackUsername, email, null, cognitoSub);

            Set<Role> roles = new HashSet<>();
            Role userRole = roleRepository.findByName(ERole.ROLE_USER)
                    .orElseThrow(() -> new RuntimeException("Error: Role is not found."));
            roles.add(userRole);
            user.setRoles(roles);

            userRepository.save(user); // Persist to RDS MySQL
        }

        // 3. Return a clean JSON profile payload so the Next.js Frontend knows who they
        // are
        Map<String, Object> response = new HashMap<>();
        response.put("id", user.getId());
        response.put("username", user.getUsername());
        response.put("email", user.getEmail());
        response.put("cognitoSub", user.getCognitoSub());

        // Pass the raw token through so existing frontend Cart logic can use it
        response.put("accessToken", jwt.getTokenValue());

        return ResponseEntity.ok(response);
    }
}
