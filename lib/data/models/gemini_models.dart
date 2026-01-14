class GeminiAnalysisRequest {
  final List<DiaryEntry> diaries;
  final List<MemoryEntry> memories;
  final AnalysisOptions options;

  GeminiAnalysisRequest({
    required this.diaries,
    this.memories = const [],
    this.options = const AnalysisOptions(),
  });

  Map<String, dynamic> toJson() {
    return {
      'diaries': diaries.map((e) => e.toJson()).toList(),
      'memories': memories.map((e) => e.toJson()).toList(),
      'options': options.toJson(),
    };
  }
}

class DiaryEntry {
  final String id;
  final String content;
  final String date;

  DiaryEntry({required this.id, required this.content, required this.date});

  Map<String, dynamic> toJson() {
    return {'id': id, 'content': content, 'date': date};
  }
}

class MemoryEntry {
  final String id;
  final String content;
  final int? score; // Added score field

  MemoryEntry({required this.id, required this.content, this.score});

  Map<String, dynamic> toJson() {
    final map = {'id': id, 'content': content};
    if (score != null) {
      map['score'] = score as String;
    }
    return map;
  }

  factory MemoryEntry.fromJson(Map<String, dynamic> json) {
    return MemoryEntry(
      id: json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      score: json['score'] as int?,
    );
  }
}

class AnalysisOptions {
  final bool dailyText;
  final bool moodSentences;
  final bool memories;

  const AnalysisOptions({
    this.dailyText = true,
    this.moodSentences = true,
    this.memories = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'daily_text': dailyText,
      'mood_sentences': moodSentences,
      'memories': memories,
    };
  }
}

class GeminiAnalysisResponse {
  final bool success;
  final AnalysisData? data;
  final AnalysisError? error;

  GeminiAnalysisResponse({required this.success, this.data, this.error});

  factory GeminiAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return GeminiAnalysisResponse(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null
          ? AnalysisData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      error: json['error'] != null
          ? AnalysisError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AnalysisData {
  final String? dailyText;
  final Map<String, String>? moodSentences;
  final List<MemoryEntry>? finalMemories;

  AnalysisData({this.dailyText, this.moodSentences, this.finalMemories});

  factory AnalysisData.fromJson(Map<String, dynamic> json) {
    return AnalysisData(
      dailyText: json['daily_text'] as String?,
      moodSentences: (json['mood_sentences'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
      finalMemories: (json['final_memories'] as List<dynamic>?)
          ?.map((e) => MemoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AnalysisError {
  final String message;
  final String code;

  AnalysisError({required this.message, required this.code});

  factory AnalysisError.fromJson(Map<String, dynamic> json) {
    return AnalysisError(
      message: json['message'] as String? ?? 'Unknown error',
      code: json['code'] as String? ?? 'UNKNOWN_CODE',
    );
  }
}
