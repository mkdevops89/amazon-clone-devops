package com.amazonlike.backend.service;

import com.amazonlike.backend.config.RabbitMQConfig;
import com.amazonlike.backend.model.Order;
import com.amazonlike.backend.repository.OrderRepository;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.math.BigDecimal;

@Service
public class OrderService {

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private RabbitTemplate rabbitTemplate;

    public Order placeOrder(String username, BigDecimal amount) {
        // 1. Save initial order state to MySQL
        Order order = new Order(username, amount, "PENDING");
        Order savedOrder = orderRepository.save(order);

        // 2. Publish event to RabbitMQ for async processing (Shipping/Inventory)
        rabbitTemplate.convertAndSend(RabbitMQConfig.ORDER_QUEUE, "Order Placed: " + savedOrder.getId());

        return savedOrder;
    }
}
