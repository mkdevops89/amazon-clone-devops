package com.amazonlike.backend.service;

import com.amazonlike.backend.model.Product;
import com.amazonlike.backend.repository.ProductRepository;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class ChatService {

    private final ChatClient chatClient;
    private final ProductRepository productRepository;

    public ChatService(ChatClient.Builder chatClientBuilder, ProductRepository productRepository) {
        this.chatClient = chatClientBuilder.build();
        this.productRepository = productRepository;
    }

    public Flux<String> chatStream(String userMessage) {
        // RAG Retrieval Phase: Fetch entire catalog
        List<Product> products = productRepository.findAll();

        // Context Generation Phase: Build the context window for the AI to read
        String productContext = products.stream()
                .map(p -> String.format("- %s (ID: %d): $%.2f. %s", p.getName(), p.getId(), p.getPrice(),
                        p.getDescription()))
                .collect(Collectors.joining("\n"));

        String systemPrompt = "You are a helpful and friendly shop assistant for an e-commerce platform called AmazonLike. "
                +
                "You help users find products, recommend gifts, and answer questions about the catalog. " +
                "Here is the current live product catalog:\n" + productContext + "\n" +
                "Do not make up products. Only recommend items from this list. If a user asks for something we do not have, politely tell them.";

        // RAG Execution Phase: Query Claude 3 Haiku via Bedrock
        return this.chatClient.prompt()
                .system(systemPrompt)
                .user(userMessage)
                .stream()
                .content();
    }
}
