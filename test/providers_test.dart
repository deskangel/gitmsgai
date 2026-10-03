import 'dart:convert';
import 'package:gitmsgai/gitmsgai.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderFactory Tests', () {
    final config = AppConfig.defaults();

    test('creates deepseek provider', () {
      final p = ProviderFactory.create('deepseek', config);
      expect(p, isA<DeepSeekProvider>());
      expect(p.name, equals('deepseek'));
    });

    test('creates gemini provider', () {
      final p = ProviderFactory.create('gemini', config);
      expect(p, isA<GeminiProvider>());
      expect(p.name, equals('gemini'));
    });

    test('creates openai provider', () {
      final p = ProviderFactory.create('openai', config);
      expect(p, isA<OpenAiProvider>());
      expect(p.name, equals('openai'));
    });

    test('throws ArgumentError on unknown provider', () {
      expect(
        () => ProviderFactory.create('unknown_ai', config),
        throwsArgumentError,
      );
    });
  });

  group('OpenAiProvider Tests', () {
    const context = CommitPromptContext(diff: 'diff content', stagedFiles: []);

    test('throws AiException when apiKey is missing', () async {
      final provider = OpenAiProvider(
        const ProviderConfig(model: 'gpt-4o-mini'),
      );
      expect(
        () => provider.generateCommitMessage(context),
        throwsA(
          isA<AiException>().having(
            (e) => e.message,
            'message',
            contains('API Key is missing'),
          ),
        ),
      );
    });

    test('sends correct request and parses assistant message', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          equals('https://api.openai.com/v1/chat/completions'),
        );
        expect(
          request.headers['Authorization'],
          equals('Bearer test-openai-key'),
        );
        expect(request.headers['Content-Type'], contains('application/json'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['model'], equals('gpt-4o-mini'));
        expect(body['messages'], isList);

        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'role': 'assistant',
                  'content': 'feat(auth): add OAuth2 provider support',
                },
              },
            ],
          }),
          200,
        );
      });

      final provider = OpenAiProvider(
        const ProviderConfig(model: 'gpt-4o-mini', apiKey: 'test-openai-key'),
        client: mockClient,
      );

      final result = await provider.generateCommitMessage(context);
      expect(result, equals('feat(auth): add OAuth2 provider support'));
    });

    test('handles OpenAI API error response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'message': 'Quota exceeded'},
          }),
          429,
        );
      });

      final provider = OpenAiProvider(
        const ProviderConfig(model: 'gpt-4o-mini', apiKey: 'test-key'),
        client: mockClient,
      );

      expect(
        () => provider.generateCommitMessage(context),
        throwsA(
          isA<AiException>()
              .having((e) => e.statusCode, 'statusCode', equals(429))
              .having((e) => e.message, 'message', equals('Quota exceeded')),
        ),
      );
    });
  });

  group('DeepSeekProvider Tests', () {
    const context = CommitPromptContext(diff: 'diff content', stagedFiles: []);

    test('uses deepseek defaults and handles response', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          equals('https://api.deepseek.com/chat/completions'),
        );
        expect(
          request.headers['Authorization'],
          equals('Bearer test-deepseek-key'),
        );

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['model'], equals('deepseek-chat'));

        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'role': 'assistant',
                  'content': 'fix(parser): resolve json payload boundary error',
                },
              },
            ],
          }),
          200,
        );
      });

      final provider = DeepSeekProvider(
        const ProviderConfig(
          model: 'deepseek-chat',
          apiKey: 'test-deepseek-key',
        ),
        client: mockClient,
      );

      final result = await provider.generateCommitMessage(context);
      expect(
        result,
        equals('fix(parser): resolve json payload boundary error'),
      );
    });
  });

  group('GeminiProvider Tests', () {
    const context = CommitPromptContext(diff: 'diff content', stagedFiles: []);

    test('throws AiException when apiKey is missing', () async {
      final provider = GeminiProvider(
        const ProviderConfig(model: 'gemini-2.5-flash'),
      );
      expect(
        () => provider.generateCommitMessage(context),
        throwsA(
          isA<AiException>().having(
            (e) => e.message,
            'message',
            contains('API Key is missing'),
          ),
        ),
      );
    });

    test('sends correct request and parses candidate text', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          equals(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=test-gemini-key',
          ),
        );

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.containsKey('system_instruction'), isTrue);
        expect(body.containsKey('contents'), isTrue);

        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'chore: update dependency versions'},
                  ],
                  'role': 'model',
                },
                'finishReason': 'STOP',
              },
            ],
          }),
          200,
        );
      });

      final provider = GeminiProvider(
        const ProviderConfig(
          model: 'gemini-2.5-flash',
          apiKey: 'test-gemini-key',
        ),
        client: mockClient,
      );

      final result = await provider.generateCommitMessage(context);
      expect(result, equals('chore: update dependency versions'));
    });

    test('handles Gemini API error message', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 400,
              'message': 'API_KEY_INVALID',
              'status': 'INVALID_ARGUMENT',
            },
          }),
          400,
        );
      });

      final provider = GeminiProvider(
        const ProviderConfig(model: 'gemini-2.5-flash', apiKey: 'invalid-key'),
        client: mockClient,
      );

      expect(
        () => provider.generateCommitMessage(context),
        throwsA(
          isA<AiException>()
              .having((e) => e.statusCode, 'statusCode', equals(400))
              .having((e) => e.message, 'message', equals('API_KEY_INVALID')),
        ),
      );
    });
  });
}
