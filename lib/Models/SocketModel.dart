// To parse this JSON data, do
//
//     final socketModel = socketModelFromJson(jsonString);

// ignore_for_file: file_names

import 'dart:convert';

SocketModel socketModelFromJson(String str) =>
    SocketModel.fromJson(json.decode(str));

String socketModelToJson(SocketModel data) => json.encode(data.toJson());

class SocketModel {
  int type;
  String target;
  List<Argument> arguments;

  SocketModel({
    required this.type,
    required this.target,
    required this.arguments,
  });

  factory SocketModel.fromJson(Map<String, dynamic> json) => SocketModel(
        type: json["type"] ?? 0,
        target: json["target"] ?? "",
        arguments: (json["arguments"] as List<dynamic>?)
                ?.map((x) => Argument.fromJson(x))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        "target": target,
        "arguments": List<dynamic>.from(arguments.map((x) => x.toJson())),
      };
}

class Argument {
  int messageType;
  String fromUser;
  String data;

  Argument({
    required this.messageType,
    required this.fromUser,
    required this.data,
  });

  factory Argument.fromJson(Map<String, dynamic> json) => Argument(
        messageType: json["messageType"] ?? 0,
        fromUser: json["fromUser"] ?? "",
        data: json["data"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "messageType": messageType,
        "fromUser": fromUser,
        "data": data,
      };
}
