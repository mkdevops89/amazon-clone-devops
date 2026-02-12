package com.amazonlike.backend.model;

import jakarta.persistence.*;

@Entity
@Table(name = "cart_items")
public class CartItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user; // Logged in user (optional if using session)

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "product_id", nullable = false)
    private Product product;

    @Column(nullable = false)
    private int quantity;

    @Column(name = "session_id")
    private String sessionId; // For anonymous carts

    public CartItem() {
    }

    @edu.umd.cs.findbugs.annotations.SuppressFBWarnings(value = "EI_EXPOSE_REP2", justification = "JPA Entity requires mutable access")
    public CartItem(User user, Product product, int quantity, String sessionId) {
        this.user = user;
        this.product = product;
        this.quantity = quantity;
        this.sessionId = sessionId;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    @edu.umd.cs.findbugs.annotations.SuppressFBWarnings(value = "EI_EXPOSE_REP", justification = "JPA Entity requires mutable access")
    public User getUser() {
        return user;
    }

    @edu.umd.cs.findbugs.annotations.SuppressFBWarnings(value = "EI_EXPOSE_REP2", justification = "JPA Entity requires mutable access")
    public void setUser(User user) {
        this.user = user;
    }

    @edu.umd.cs.findbugs.annotations.SuppressFBWarnings(value = "EI_EXPOSE_REP", justification = "JPA Entity requires mutable access")
    public Product getProduct() {
        return product;
    }

    @edu.umd.cs.findbugs.annotations.SuppressFBWarnings(value = "EI_EXPOSE_REP2", justification = "JPA Entity requires mutable access")
    public void setProduct(Product product) {
        this.product = product;
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
