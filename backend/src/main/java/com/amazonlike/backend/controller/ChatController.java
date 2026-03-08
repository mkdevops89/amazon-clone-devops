package com.amazonlike.backend.controller;

import com.amazonlike.backend.service.ChatService;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;

import java.util.List;
import java.util.Map;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/chat")
public class ChatController {

    private final ChatService chatService;

    public ChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    @SuppressWarnings("unchecked")
    @PostMapping(produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<String> chat(@RequestBody Map<String, Object> payload) {
        // Vercel AI SDK heavily uses a {"messages": [...]} structure
        List<Map<String, String>> messages = (List<Map<String, String>>) payload.get("messages");
        String userMessage = "";

        // Extract the absolute latest message the user dispatched
        if (messages != null && !messages.isEmpty()) {
            userMessage = messages.get(messages.size() - 1).get("content");
        } else if (payload.containsKey("prompt")) {
            userMessage = (String) payload.get("prompt");
        }

        return chatService.chatStream(userMessage);
    }
}
