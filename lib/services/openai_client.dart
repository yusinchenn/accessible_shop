/// openai_client.dart
/// A Dart client compatible with OpenAI's Chat Completion API, supporting both
/// standard and streaming responses via Dio, with error handling and logging.
/// https://api-docs.deepseek.com
library;

/// Core Dart async and JSON encoding
import 'dart:async';
import 'dart:convert';

/// Dio HTTP client for REST and streaming requests
import 'package:dio/dio.dart';

//// ------------ 基本資料結構 ------------

/// Defines the role of a chat message: system, user, assistant, or function.
enum Role { system, user, assistant, function }

/// Represents a single message in the conversation, with role and content.
class ChatMessage {
  /// The role of the message originator
  final Role role;

  /// The text content of the message, mutable for streaming
  String content;

  /// Optional name for function messages
  final String? name; // optional
  /// Optional data for function call responses
  final Map<String, dynamic>? functionCallResult; // for function response

  /// Constructor to create a chat message instance
  ChatMessage({
    required this.role,
    required this.content,
    this.name,
    this.functionCallResult,
  });

  /// Serializes the ChatMessage to JSON for API requests
  Map<String, dynamic> toJson() => {
    'role': role.name,
    'content': content,
    if (name != null) 'name': name,
    if (functionCallResult != null) 'function_call': functionCallResult,
  };
}

/// Configuration for different AI service providers: endpoint, API key, and model.
class ProviderConfig {
  /// Friendly provider name
  final String name;

  /// Base URL for the API
  final String baseUrl; // e.g. https://api.openai.com/v1
  /// API key for authentication
  final String apiKey;

  /// Default model to use if not specified in request
  final String defaultModel;

  /// Extra HTTP headers to include in requests
  final Map<String, String> extraHeaders;

  const ProviderConfig({
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.defaultModel,
    this.extraHeaders = const {},
  });
}

/// Options for chat completion requests, including model, messages, streaming,
/// and optional OpenAI parameters for temperature, max tokens, tools, etc.
class ChatCompletionOptions {
  /// Model name to use for completion (overrides default)
  final String? model;

  /// List of messages forming the conversation context
  final List<ChatMessage> messages;

  /// Whether to stream responses (SSE) or not
  final bool stream;

  /// Sampling temperature to use, between 0 and 2
  final double? temperature;

  /// Nucleus sampling parameter
  final double? topP;

  /// Maximum number of tokens to generate
  final int? maxTokens;

  /// Frequency penalty to reduce repetition
  final double? frequencyPenalty;

  /// Presence penalty to encourage new topics
  final double? presencePenalty;

  /// Stop sequences to end generation
  final dynamic stop; // String or List<String>
  /// Response format customization
  final Map<String, dynamic>? responseFormat;

  /// List of tools (functions) available for the model
  final List<Map<String, dynamic>>? tools;

  /// Tool usage choice mode: "none", "auto", "required", or custom
  final dynamic toolChoice; // "none" | "auto" | "required" | {...}
  /// Whether to include log probabilities in response
  final bool? logprobs;

  /// Number of top log probabilities to include
  final int? topLogprobs;

  /// Vendor-specific extra parameters to pass through
  final Map<String, dynamic> extraParams;

  ChatCompletionOptions({
    required this.messages,
    this.model,
    this.stream = false,
    this.temperature,
    this.topP,
    this.maxTokens,
    this.frequencyPenalty,
    this.presencePenalty,
    this.stop,
    this.responseFormat,
    this.tools,
    this.toolChoice,
    this.logprobs,
    this.topLogprobs,
    this.extraParams = const {},
  });

  /// Builds the HTTP request body from the options and fallback model.
  Map<String, dynamic> toRequestBody(String fallbackModel) {
    return {
      'model': model ?? fallbackModel,
      // Map messages to JSON format expected by API
      'messages': messages.map((m) => m.toJson()).toList(),
      'stream': stream,
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'top_p': topP,
      if (maxTokens != null) 'max_tokens': maxTokens,
      if (frequencyPenalty != null) 'frequency_penalty': frequencyPenalty,
      if (presencePenalty != null) 'presence_penalty': presencePenalty,
      if (stop != null) 'stop': stop,
      if (responseFormat != null) 'response_format': responseFormat,
      if (tools != null) 'tools': tools,
      if (toolChoice != null) 'tool_choice': toolChoice,
      if (logprobs != null) 'logprobs': logprobs,
      if (topLogprobs != null) 'top_logprobs': topLogprobs,
      // Merge vendor-specific extra parameters safely
      ...extraParams, // 安全地把 vendor 專用欄位透傳
    };
  }
}

/// ------------ 核心 Client ------------
///
/// Main client class to call chat completions. Supports both non-streaming
/// and streaming (SSE) modes, with error handling and optional logging.
class OpenAICompatibleClient {
  final ProviderConfig _config;
  late final Dio _dio;

  /// Initializes Dio with base URL, headers, JSON response type, and interceptor.
  OpenAICompatibleClient(this._config) {
    _dio =
        Dio(
            BaseOptions(
              baseUrl: _config.baseUrl,
              headers: {
                'Authorization': 'Bearer ${_config.apiKey}',
                'Content-Type': 'application/json',
                ..._config.extraHeaders,
              },
              responseType: ResponseType.json,
              // Accept any status below 500 as valid to handle errors gracefully
              validateStatus: (status) => status != null && status < 500,
            ),
          )
          ..interceptors.add(
            // Log request and response bodies for debugging
            LogInterceptor(requestBody: true, responseBody: true),
          );
  }

  /// Sends a non-streaming chat completion request, returning full text.
  Future<String> chatCompletion(ChatCompletionOptions opts) async {
    if (opts.stream) {
      throw ArgumentError('Use chatCompletionStream() for stream=true');
    }
    final res = await _post(opts.toRequestBody(_config.defaultModel));
    return _extractContent(res);
  }

  /// Sends a streaming chat completion request, yielding content chunks as they arrive.
  Stream<String> chatCompletionStream(ChatCompletionOptions opts) async* {
    // Build request body and enforce stream: true
    final body = opts.toRequestBody(_config.defaultModel)..['stream'] = true;

    // Post request with responseType set to stream for SSE
    final Response<ResponseBody> response = await _dio.post<ResponseBody>(
      '/chat/completions',
      data: jsonEncode(body),
      options: Options(
        responseType: ResponseType.stream,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Check HTTP status code, throw if not 200 OK
    if (response.statusCode != 200) {
      throw OpenAIException(
        'HTTP ${response.statusCode}: ${response.data?.toString()}',
      );
    }

    // Get raw byte stream from response
    final byteStream = response.data!.stream;
    // Decode bytes to UTF8 and split lines for SSE parsing
    final decodedStream = utf8.decoder
        .bind(byteStream)
        .transform(const LineSplitter());
    await for (final line in decodedStream) {
      if (line.trim().isEmpty) continue;
      // Strip 'data:' prefix from SSE event line
      final cleaned = line.startsWith('data:')
          ? line.substring(5).trim()
          : line.trim();
      if (cleaned == '[DONE]') break;
      final jsonChunk = jsonDecode(cleaned) as Map<String, dynamic>;
      // print(jsonChunk.toString());
      final delta = (jsonChunk['choices'] as List).first['delta'];
      // Yield content chunks as they arrive
      if (delta != null && delta['content'] != null) {
        yield delta['content'] as String;
      }
    }
  }

  /// Internal helper to perform non-streaming POST and return parsed JSON.
  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/chat/completions',
        data: jsonEncode(body),
      );
      if (res.statusCode == 200 && res.data != null) {
        return res.data!;
      }
      throw OpenAIException(
        'HTTP ${res.statusCode}: ${res.data ?? 'unknown error'}',
      );
    } on DioException catch (e) {
      // Convert Dio exceptions to OpenAIException with status code and message
      throw OpenAIException(
        'HTTP ${e.response?.statusCode ?? ''}: ${e.response?.data ?? e.message}',
      );
    }
  }

  /// Extracts the 'content' field from the API response JSON.
  String _extractContent(Map<String, dynamic> resp) {
    final choices = resp['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw OpenAIException('No choices in response');
    }
    final msg = choices.first['message']?['content'];
    if (msg is! String) {
      throw OpenAIException('Invalid content type');
    }
    return msg;
  }
}

/// Custom exception class for OpenAI API errors.
class OpenAIException implements Exception {
  // Error message from API or client
  final String message;
  OpenAIException(this.message);

  @override
  String toString() => 'OpenAIException: $message';
}

// final provider = ProviderConfig(
//   name: 'DeepSeek',
//   baseUrl: 'https://api.deepseek.com',
//   apiKey: '<YOUR_KEY>',
//   defaultModel: 'deepseek-chat',
// );

// final client = OpenAICompatibleClient(provider);

// final reply = await client.chatCompletion(
//   ChatCompletionOptions(
//     messages: [
//       ChatMessage(role: Role.system, content: 'You are a helpful assistant.'),
//       ChatMessage(role: Role.user, content: '用中文列出 3 個 Dart 的優點'),
//     ],
//     temperature: 0.7,
//     extraParams: { 'chat_prefix': '以下是回答：' }, // DeepSeek 專用
//   ),
// );

// print(reply);

// // ---- 或串流 ----
// await for (final delta in client.chatCompletionStream(
//   ChatCompletionOptions(
//     messages: [
//       ChatMessage(role: Role.user, content: 'Explain SSE streaming briefly.'),
//     ],
//     stream: true,
//   ),
// )) {
//   stdout.write(delta);
// }
