package com.democloudproject.gateway

import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController


@RestController
class TestController {
    @GetMapping("/test")
    fun helloWorld(): String {
        return "Hello, World!"
    }

    @GetMapping("/")
    fun healthCheck(): String {
        return "OK"
    }
}
