// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clinical_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClinicalLogEntryAdapter extends TypeAdapter<ClinicalLogEntry> {
  @override
  final int typeId = 2;

  @override
  ClinicalLogEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClinicalLogEntry(
      id: fields[0] as String,
      bodyArea: fields[1] as String,
      condition: fields[2] as String,
      loggedAt: fields[3] as DateTime,
      confidence: fields[4] as double,
      risk: fields[5] as RiskLevel,
      status: fields[6] as LogStatus,
      trend: (fields[7] as List).cast<double>(),
      recommendations: (fields[9] as List).cast<String>(),
      icon: fields[8] as IconData,
      imagePath: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ClinicalLogEntry obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.bodyArea)
      ..writeByte(2)
      ..write(obj.condition)
      ..writeByte(3)
      ..write(obj.loggedAt)
      ..writeByte(4)
      ..write(obj.confidence)
      ..writeByte(5)
      ..write(obj.risk)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.trend)
      ..writeByte(8)
      ..write(obj.icon)
      ..writeByte(9)
      ..write(obj.recommendations)
      ..writeByte(10)
      ..write(obj.imagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClinicalLogEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RiskLevelAdapter extends TypeAdapter<RiskLevel> {
  @override
  final int typeId = 0;

  @override
  RiskLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RiskLevel.low;
      case 1:
        return RiskLevel.moderate;
      case 2:
        return RiskLevel.high;
      default:
        return RiskLevel.low;
    }
  }

  @override
  void write(BinaryWriter writer, RiskLevel obj) {
    switch (obj) {
      case RiskLevel.low:
        writer.writeByte(0);
        break;
      case RiskLevel.moderate:
        writer.writeByte(1);
        break;
      case RiskLevel.high:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RiskLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LogStatusAdapter extends TypeAdapter<LogStatus> {
  @override
  final int typeId = 1;

  @override
  LogStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LogStatus.monitoring;
      case 1:
        return LogStatus.resolved;
      case 2:
        return LogStatus.escalated;
      default:
        return LogStatus.monitoring;
    }
  }

  @override
  void write(BinaryWriter writer, LogStatus obj) {
    switch (obj) {
      case LogStatus.monitoring:
        writer.writeByte(0);
        break;
      case LogStatus.resolved:
        writer.writeByte(1);
        break;
      case LogStatus.escalated:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
