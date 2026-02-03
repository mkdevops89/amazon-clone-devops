package com.amazonlike.backend.controller;

import com.amazonlike.backend.model.CartItem;
import com.amazonlike.backend.model.Product;
import com.amazonlike.backend.model.User;
import com.amazonlike.backend.repository.CartRepository;
import com.amazonlike.backend.repository.ProductRepository;
import com.amazonlike.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/cart")
public class CartController {

    @Autowired
    CartRepository cartRepository;

    @Autowired
    ProductRepository productRepository;

    @Autowired
    UserRepository userRepository;

    @GetMapping
    public ResponseEntity<List<CartItem>> getCart(
            @RequestParam(value = "sessionId", required = false) String sessionId) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.isAuthenticated() && !auth.getPrincipal().equals("anonymousUser")) {
            // Authenticated User
            String username = auth.getName(); // Actually returns username from UserDetails
            // In previous JwtUtils, we set UserDetails as principal.
            // We need to fetch User entity.
            Optional<User> user = userRepository.findByUsername(username);
            if (user.isPresent()) {
                return ResponseEntity.ok(cartRepository.findByUser(user.get()));
            }
        }

        // Fallback to Session ID (Anonymous)
        if (sessionId != null) {
            return ResponseEntity.ok(cartRepository.findBySessionId(sessionId));
        }

        return ResponseEntity.badRequest().build();
    }

    @PostMapping("/add")
    public ResponseEntity<?> addToCart(@RequestBody AddCartRequest request) {
        Product product = productRepository.findById(request.getProductId())
                .orElseThrow(() -> new RuntimeException("Product not found"));

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        User user = null;
        if (auth != null && auth.isAuthenticated() && !auth.getPrincipal().equals("anonymousUser")) {
            // Use Username from Context because Principal is UserDetailsImpl
            // See UserDetailsServiceImpl.loadUserByUsername -> returns UserDetailsImpl
            // AuthTokenFilter sets this authentication.
            // But note: auth.getName() on UsernamePasswordAuthenticationToken returns the
            // name.
            // Let's use the simple username lookup for now.
            String username = ((org.springframework.security.core.userdetails.UserDetails) auth.getPrincipal())
                    .getUsername();
            user = userRepository.findByUsername(username).orElse(null);
        }

        if (user != null) {
            Optional<CartItem> existing = cartRepository.findByUserAndProductId(user, product.getId());
            if (existing.isPresent()) {
                CartItem item = existing.get();
                item.setQuantity(item.getQuantity() + request.getQuantity());
                cartRepository.save(item);
            } else {
                cartRepository.save(new CartItem(user, product, request.getQuantity(), null));
            }
        } else if (request.getSessionId() != null) {
            Optional<CartItem> existing = cartRepository.findBySessionIdAndProductId(request.getSessionId(),
                    product.getId());
            if (existing.isPresent()) {
                CartItem item = existing.get();
                item.setQuantity(item.getQuantity() + request.getQuantity());
                cartRepository.save(item);
            } else {
                cartRepository.save(new CartItem(null, product, request.getQuantity(), request.getSessionId()));
            }
        } else {
            return ResponseEntity.badRequest().body("User or Session ID required");
        }

        return ResponseEntity.ok("Item added to cart");
    }
}

// Inner DTO or Separate file? Let's keep it separate if complex, but simple for
// now.
class AddCartRequest {
    private Long productId;
    private int quantity;
    private String sessionId;

    // Getters/Setters
    public Long getProductId() {
        return productId;
    }

    public void setProductId(Long productId) {
        this.productId = productId;
    }

    public int getQuantity() {
        return quantity;
    }

    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }

    public String getSessionId() {
        return sessionId;
    }

    public void setSessionId(String sessionId) {
        this.sessionId = sessionId;
    }
}
