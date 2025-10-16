import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'app_config.dart';

/// Parser for loading and parsing the YAML configuration file
class ConfigParser {
  static const String _configPath = 'assets/config.yaml';

  /// Loads the configuration from the YAML file
  static Future<AppConfig> loadConfig() async {
    try {
      // Load the YAML file from assets
      final String yamlString = await rootBundle.loadString(_configPath);

      // Parse the YAML
      final YamlMap yamlMap = loadYaml(yamlString) as YamlMap;

      // Convert YamlMap to regular Map
      final Map<dynamic, dynamic> configMap = _yamlMapToMap(yamlMap);

      // Create and return AppConfig
      return AppConfig.fromMap(configMap);
    } catch (e) {
      throw Exception('Failed to load config: $e');
    }
  }

  /// Recursively converts YamlMap to regular Map
  static Map<dynamic, dynamic> _yamlMapToMap(YamlMap yamlMap) {
    final Map<dynamic, dynamic> map = {};

    yamlMap.forEach((key, value) {
      if (value is YamlMap) {
        map[key] = _yamlMapToMap(value);
      } else if (value is YamlList) {
        map[key] = _yamlListToList(value);
      } else {
        map[key] = value;
      }
    });

    return map;
  }

  /// Recursively converts YamlList to regular List
  static List<dynamic> _yamlListToList(YamlList yamlList) {
    final List<dynamic> list = [];

    for (var item in yamlList) {
      if (item is YamlMap) {
        list.add(_yamlMapToMap(item));
      } else if (item is YamlList) {
        list.add(_yamlListToList(item));
      } else {
        list.add(item);
      }
    }

    return list;
  }
}
