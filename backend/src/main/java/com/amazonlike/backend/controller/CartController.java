package com.amazonlike.backend.controller;

import com.amazonlike.backend.model.CartItem;
import com.amazonlike.backend.service.CartService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/cart")
public class CartController {

    @Autowired
    private CartService cartService;

    @PostMapping("/{username}")
    public void addToCart(@PathVariable String username, @RequestBody CartItem item) {
        cartService.addToCart(username, item);
    }

    @GetMapping("/{username}")
    public List<CartItem> getCart(@PathVariable String username) {
        return cartService.getCart(username);
    }

    @DeleteMapping("/{username}")
    public void clearCart(@PathVariable String username) {
        cartService.clearCart(username);
    }
}
