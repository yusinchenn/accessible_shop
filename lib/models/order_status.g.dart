// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_status.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOrderStatusHistoryCollection on Isar {
  IsarCollection<OrderStatusHistory> get orderStatusHistorys =>
      this.collection();
}

const OrderStatusHistorySchema = CollectionSchema(
  name: r'OrderStatusHistory',
  id: -601774231729408541,
  properties: {
    r'description': PropertySchema(
      id: 0,
      name: r'description',
      type: IsarType.string,
    ),
    r'logisticsStatus': PropertySchema(
      id: 1,
      name: r'logisticsStatus',
      type: IsarType.string,
      enumMap: _OrderStatusHistorylogisticsStatusEnumValueMap,
    ),
    r'mainStatus': PropertySchema(
      id: 2,
      name: r'mainStatus',
      type: IsarType.string,
      enumMap: _OrderStatusHistorymainStatusEnumValueMap,
    ),
    r'note': PropertySchema(
      id: 3,
      name: r'note',
      type: IsarType.string,
    ),
    r'orderId': PropertySchema(
      id: 4,
      name: r'orderId',
      type: IsarType.long,
    ),
    r'timestamp': PropertySchema(
      id: 5,
      name: r'timestamp',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _orderStatusHistoryEstimateSize,
  serialize: _orderStatusHistorySerialize,
  deserialize: _orderStatusHistoryDeserialize,
  deserializeProp: _orderStatusHistoryDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _orderStatusHistoryGetId,
  getLinks: _orderStatusHistoryGetLinks,
  attach: _orderStatusHistoryAttach,
  version: '3.1.0+1',
);

int _orderStatusHistoryEstimateSize(
  OrderStatusHistory object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.description.length * 3;
  bytesCount += 3 + object.logisticsStatus.name.length * 3;
  bytesCount += 3 + object.mainStatus.name.length * 3;
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _orderStatusHistorySerialize(
  OrderStatusHistory object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.description);
  writer.writeString(offsets[1], object.logisticsStatus.name);
  writer.writeString(offsets[2], object.mainStatus.name);
  writer.writeString(offsets[3], object.note);
  writer.writeLong(offsets[4], object.orderId);
  writer.writeDateTime(offsets[5], object.timestamp);
}

OrderStatusHistory _orderStatusHistoryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OrderStatusHistory();
  object.description = reader.readString(offsets[0]);
  object.id = id;
  object.logisticsStatus = _OrderStatusHistorylogisticsStatusValueEnumMap[
          reader.readStringOrNull(offsets[1])] ??
      LogisticsStatus.none;
  object.mainStatus = _OrderStatusHistorymainStatusValueEnumMap[
          reader.readStringOrNull(offsets[2])] ??
      OrderMainStatus.pendingPayment;
  object.note = reader.readStringOrNull(offsets[3]);
  object.orderId = reader.readLong(offsets[4]);
  object.timestamp = reader.readDateTime(offsets[5]);
  return object;
}

P _orderStatusHistoryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (_OrderStatusHistorylogisticsStatusValueEnumMap[
              reader.readStringOrNull(offset)] ??
          LogisticsStatus.none) as P;
    case 2:
      return (_OrderStatusHistorymainStatusValueEnumMap[
              reader.readStringOrNull(offset)] ??
          OrderMainStatus.pendingPayment) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _OrderStatusHistorylogisticsStatusEnumValueMap = {
  r'none': r'none',
  r'inTransit': r'inTransit',
  r'arrivedAtPickupPoint': r'arrivedAtPickupPoint',
  r'signed': r'signed',
};
const _OrderStatusHistorylogisticsStatusValueEnumMap = {
  r'none': LogisticsStatus.none,
  r'inTransit': LogisticsStatus.inTransit,
  r'arrivedAtPickupPoint': LogisticsStatus.arrivedAtPickupPoint,
  r'signed': LogisticsStatus.signed,
};
const _OrderStatusHistorymainStatusEnumValueMap = {
  r'pendingPayment': r'pendingPayment',
  r'pendingShipment': r'pendingShipment',
  r'pendingDelivery': r'pendingDelivery',
  r'completed': r'completed',
  r'returnRefund': r'returnRefund',
  r'invalid': r'invalid',
};
const _OrderStatusHistorymainStatusValueEnumMap = {
  r'pendingPayment': OrderMainStatus.pendingPayment,
  r'pendingShipment': OrderMainStatus.pendingShipment,
  r'pendingDelivery': OrderMainStatus.pendingDelivery,
  r'completed': OrderMainStatus.completed,
  r'returnRefund': OrderMainStatus.returnRefund,
  r'invalid': OrderMainStatus.invalid,
};

Id _orderStatusHistoryGetId(OrderStatusHistory object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _orderStatusHistoryGetLinks(
    OrderStatusHistory object) {
  return [];
}

void _orderStatusHistoryAttach(
    IsarCollection<dynamic> col, Id id, OrderStatusHistory object) {
  object.id = id;
}

extension OrderStatusHistoryQueryWhereSort
    on QueryBuilder<OrderStatusHistory, OrderStatusHistory, QWhere> {
  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension OrderStatusHistoryQueryWhere
    on QueryBuilder<OrderStatusHistory, OrderStatusHistory, QWhereClause> {
  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension OrderStatusHistoryQueryFilter
    on QueryBuilder<OrderStatusHistory, OrderStatusHistory, QFilterCondition> {
  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      descriptionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      descriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      descriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      descriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      logisticsStatusEqualTo(
    LogisticsStatus value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'logisticsStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      logisticsStatusGreaterThan(
    LogisticsStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'logisticsStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      logisticsStatusLessThan(
    LogisticsStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'logisticsStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      logisticsStatusBetween(
    LogisticsStatus lower,
    LogisticsStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'logisticsStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      logisticsStatusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'logisticsStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      logisticsStatusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'logisticsStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      logisticsStatusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'logisticsStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      logisticsStatusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'logisticsStatus',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      logisticsStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'logisticsStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      logisticsStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'logisticsStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      mainStatusEqualTo(
    OrderMainStatus value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mainStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      mainStatusGreaterThan(
    OrderMainStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mainStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      mainStatusLessThan(
    OrderMainStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mainStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      mainStatusBetween(
    OrderMainStatus lower,
    OrderMainStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mainStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      mainStatusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mainStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      mainStatusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mainStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      mainStatusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mainStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      mainStatusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mainStatus',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      mainStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mainStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      mainStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mainStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      noteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      noteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      noteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      noteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'note',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      noteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      noteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'note',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      orderIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderId',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      orderIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'orderId',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      orderIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'orderId',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      orderIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'orderId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterFilterCondition>
      timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension OrderStatusHistoryQueryObject
    on QueryBuilder<OrderStatusHistory, OrderStatusHistory, QFilterCondition> {}

extension OrderStatusHistoryQueryLinks
    on QueryBuilder<OrderStatusHistory, OrderStatusHistory, QFilterCondition> {}

extension OrderStatusHistoryQuerySortBy
    on QueryBuilder<OrderStatusHistory, OrderStatusHistory, QSortBy> {
  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      sortByLogisticsStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logisticsStatus', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      sortByLogisticsStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logisticsStatus', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      sortByMainStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainStatus', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      sortByMainStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainStatus', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      sortByOrderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderId', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      sortByOrderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderId', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension OrderStatusHistoryQuerySortThenBy
    on QueryBuilder<OrderStatusHistory, OrderStatusHistory, QSortThenBy> {
  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      thenByLogisticsStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logisticsStatus', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      thenByLogisticsStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logisticsStatus', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      thenByMainStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainStatus', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      thenByMainStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainStatus', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      thenByOrderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderId', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      thenByOrderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderId', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension OrderStatusHistoryQueryWhereDistinct
    on QueryBuilder<OrderStatusHistory, OrderStatusHistory, QDistinct> {
  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QDistinct>
      distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QDistinct>
      distinctByLogisticsStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'logisticsStatus',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QDistinct>
      distinctByMainStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mainStatus', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QDistinct>
      distinctByNote({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QDistinct>
      distinctByOrderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderId');
    });
  }

  QueryBuilder<OrderStatusHistory, OrderStatusHistory, QDistinct>
      distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension OrderStatusHistoryQueryProperty
    on QueryBuilder<OrderStatusHistory, OrderStatusHistory, QQueryProperty> {
  QueryBuilder<OrderStatusHistory, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<OrderStatusHistory, String, QQueryOperations>
      descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<OrderStatusHistory, LogisticsStatus, QQueryOperations>
      logisticsStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'logisticsStatus');
    });
  }

  QueryBuilder<OrderStatusHistory, OrderMainStatus, QQueryOperations>
      mainStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mainStatus');
    });
  }

  QueryBuilder<OrderStatusHistory, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<OrderStatusHistory, int, QQueryOperations> orderIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderId');
    });
  }

  QueryBuilder<OrderStatusHistory, DateTime, QQueryOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOrderStatusTimestampsCollection on Isar {
  IsarCollection<OrderStatusTimestamps> get orderStatusTimestamps =>
      this.collection();
}

const OrderStatusTimestampsSchema = CollectionSchema(
  name: r'OrderStatusTimestamps',
  id: -8234412285311710033,
  properties: {
    r'arrivedAtPickupPointAt': PropertySchema(
      id: 0,
      name: r'arrivedAtPickupPointAt',
      type: IsarType.dateTime,
    ),
    r'completedAt': PropertySchema(
      id: 1,
      name: r'completedAt',
      type: IsarType.dateTime,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'inTransitAt': PropertySchema(
      id: 3,
      name: r'inTransitAt',
      type: IsarType.dateTime,
    ),
    r'invalidAt': PropertySchema(
      id: 4,
      name: r'invalidAt',
      type: IsarType.dateTime,
    ),
    r'orderId': PropertySchema(
      id: 5,
      name: r'orderId',
      type: IsarType.long,
    ),
    r'paidAt': PropertySchema(
      id: 6,
      name: r'paidAt',
      type: IsarType.dateTime,
    ),
    r'pendingDeliveryAt': PropertySchema(
      id: 7,
      name: r'pendingDeliveryAt',
      type: IsarType.dateTime,
    ),
    r'pendingPaymentAt': PropertySchema(
      id: 8,
      name: r'pendingPaymentAt',
      type: IsarType.dateTime,
    ),
    r'pendingShipmentAt': PropertySchema(
      id: 9,
      name: r'pendingShipmentAt',
      type: IsarType.dateTime,
    ),
    r'returnRefundAt': PropertySchema(
      id: 10,
      name: r'returnRefundAt',
      type: IsarType.dateTime,
    ),
    r'signedAt': PropertySchema(
      id: 11,
      name: r'signedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _orderStatusTimestampsEstimateSize,
  serialize: _orderStatusTimestampsSerialize,
  deserialize: _orderStatusTimestampsDeserialize,
  deserializeProp: _orderStatusTimestampsDeserializeProp,
  idName: r'id',
  indexes: {
    r'orderId': IndexSchema(
      id: -6176610178429382285,
      name: r'orderId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'orderId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _orderStatusTimestampsGetId,
  getLinks: _orderStatusTimestampsGetLinks,
  attach: _orderStatusTimestampsAttach,
  version: '3.1.0+1',
);

int _orderStatusTimestampsEstimateSize(
  OrderStatusTimestamps object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _orderStatusTimestampsSerialize(
  OrderStatusTimestamps object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.arrivedAtPickupPointAt);
  writer.writeDateTime(offsets[1], object.completedAt);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeDateTime(offsets[3], object.inTransitAt);
  writer.writeDateTime(offsets[4], object.invalidAt);
  writer.writeLong(offsets[5], object.orderId);
  writer.writeDateTime(offsets[6], object.paidAt);
  writer.writeDateTime(offsets[7], object.pendingDeliveryAt);
  writer.writeDateTime(offsets[8], object.pendingPaymentAt);
  writer.writeDateTime(offsets[9], object.pendingShipmentAt);
  writer.writeDateTime(offsets[10], object.returnRefundAt);
  writer.writeDateTime(offsets[11], object.signedAt);
}

OrderStatusTimestamps _orderStatusTimestampsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OrderStatusTimestamps();
  object.arrivedAtPickupPointAt = reader.readDateTimeOrNull(offsets[0]);
  object.completedAt = reader.readDateTimeOrNull(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.id = id;
  object.inTransitAt = reader.readDateTimeOrNull(offsets[3]);
  object.invalidAt = reader.readDateTimeOrNull(offsets[4]);
  object.orderId = reader.readLong(offsets[5]);
  object.paidAt = reader.readDateTimeOrNull(offsets[6]);
  object.pendingDeliveryAt = reader.readDateTimeOrNull(offsets[7]);
  object.pendingPaymentAt = reader.readDateTimeOrNull(offsets[8]);
  object.pendingShipmentAt = reader.readDateTimeOrNull(offsets[9]);
  object.returnRefundAt = reader.readDateTimeOrNull(offsets[10]);
  object.signedAt = reader.readDateTimeOrNull(offsets[11]);
  return object;
}

P _orderStatusTimestampsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 9:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 10:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 11:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _orderStatusTimestampsGetId(OrderStatusTimestamps object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _orderStatusTimestampsGetLinks(
    OrderStatusTimestamps object) {
  return [];
}

void _orderStatusTimestampsAttach(
    IsarCollection<dynamic> col, Id id, OrderStatusTimestamps object) {
  object.id = id;
}

extension OrderStatusTimestampsByIndex
    on IsarCollection<OrderStatusTimestamps> {
  Future<OrderStatusTimestamps?> getByOrderId(int orderId) {
    return getByIndex(r'orderId', [orderId]);
  }

  OrderStatusTimestamps? getByOrderIdSync(int orderId) {
    return getByIndexSync(r'orderId', [orderId]);
  }

  Future<bool> deleteByOrderId(int orderId) {
    return deleteByIndex(r'orderId', [orderId]);
  }

  bool deleteByOrderIdSync(int orderId) {
    return deleteByIndexSync(r'orderId', [orderId]);
  }

  Future<List<OrderStatusTimestamps?>> getAllByOrderId(
      List<int> orderIdValues) {
    final values = orderIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'orderId', values);
  }

  List<OrderStatusTimestamps?> getAllByOrderIdSync(List<int> orderIdValues) {
    final values = orderIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'orderId', values);
  }

  Future<int> deleteAllByOrderId(List<int> orderIdValues) {
    final values = orderIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'orderId', values);
  }

  int deleteAllByOrderIdSync(List<int> orderIdValues) {
    final values = orderIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'orderId', values);
  }

  Future<Id> putByOrderId(OrderStatusTimestamps object) {
    return putByIndex(r'orderId', object);
  }

  Id putByOrderIdSync(OrderStatusTimestamps object, {bool saveLinks = true}) {
    return putByIndexSync(r'orderId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByOrderId(List<OrderStatusTimestamps> objects) {
    return putAllByIndex(r'orderId', objects);
  }

  List<Id> putAllByOrderIdSync(List<OrderStatusTimestamps> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'orderId', objects, saveLinks: saveLinks);
  }
}

extension OrderStatusTimestampsQueryWhereSort
    on QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QWhere> {
  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterWhere>
      anyOrderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'orderId'),
      );
    });
  }
}

extension OrderStatusTimestampsQueryWhere on QueryBuilder<OrderStatusTimestamps,
    OrderStatusTimestamps, QWhereClause> {
  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterWhereClause>
      orderIdEqualTo(int orderId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'orderId',
        value: [orderId],
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterWhereClause>
      orderIdNotEqualTo(int orderId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderId',
              lower: [],
              upper: [orderId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderId',
              lower: [orderId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderId',
              lower: [orderId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderId',
              lower: [],
              upper: [orderId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterWhereClause>
      orderIdGreaterThan(
    int orderId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'orderId',
        lower: [orderId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterWhereClause>
      orderIdLessThan(
    int orderId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'orderId',
        lower: [],
        upper: [orderId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterWhereClause>
      orderIdBetween(
    int lowerOrderId,
    int upperOrderId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'orderId',
        lower: [lowerOrderId],
        includeLower: includeLower,
        upper: [upperOrderId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension OrderStatusTimestampsQueryFilter on QueryBuilder<
    OrderStatusTimestamps, OrderStatusTimestamps, QFilterCondition> {
  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> arrivedAtPickupPointAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'arrivedAtPickupPointAt',
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> arrivedAtPickupPointAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'arrivedAtPickupPointAt',
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> arrivedAtPickupPointAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'arrivedAtPickupPointAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> arrivedAtPickupPointAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'arrivedAtPickupPointAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> arrivedAtPickupPointAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'arrivedAtPickupPointAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> arrivedAtPickupPointAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'arrivedAtPickupPointAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> completedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'completedAt',
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> completedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'completedAt',
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> completedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> completedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> completedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> completedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'completedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> inTransitAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'inTransitAt',
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> inTransitAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'inTransitAt',
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> inTransitAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'inTransitAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> inTransitAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'inTransitAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> inTransitAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'inTransitAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> inTransitAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'inTransitAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> invalidAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'invalidAt',
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> invalidAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'invalidAt',
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> invalidAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invalidAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> invalidAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'invalidAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> invalidAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'invalidAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> invalidAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'invalidAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> orderIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderId',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> orderIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'orderId',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> orderIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'orderId',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> orderIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'orderId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> paidAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'paidAt',
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> paidAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'paidAt',
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> paidAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paidAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> paidAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paidAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> paidAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paidAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> paidAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paidAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> pendingDeliveryAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pendingDeliveryAt',
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> pendingDeliveryAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pendingDeliveryAt',
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> pendingDeliveryAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pendingDeliveryAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> pendingDeliveryAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pendingDeliveryAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> pendingDeliveryAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pendingDeliveryAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> pendingDeliveryAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pendingDeliveryAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> pendingPaymentAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pendingPaymentAt',
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> pendingPaymentAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pendingPaymentAt',
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> pendingPaymentAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pendingPaymentAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> pendingPaymentAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pendingPaymentAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> pendingPaymentAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pendingPaymentAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> pendingPaymentAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pendingPaymentAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> pendingShipmentAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pendingShipmentAt',
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> pendingShipmentAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pendingShipmentAt',
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> pendingShipmentAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pendingShipmentAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> pendingShipmentAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pendingShipmentAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> pendingShipmentAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pendingShipmentAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> pendingShipmentAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pendingShipmentAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> returnRefundAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'returnRefundAt',
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> returnRefundAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'returnRefundAt',
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> returnRefundAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'returnRefundAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> returnRefundAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'returnRefundAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> returnRefundAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'returnRefundAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> returnRefundAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'returnRefundAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> signedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'signedAt',
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> signedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'signedAt',
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> signedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'signedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> signedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'signedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> signedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'signedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps,
      QAfterFilterCondition> signedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'signedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension OrderStatusTimestampsQueryObject on QueryBuilder<
    OrderStatusTimestamps, OrderStatusTimestamps, QFilterCondition> {}

extension OrderStatusTimestampsQueryLinks on QueryBuilder<OrderStatusTimestamps,
    OrderStatusTimestamps, QFilterCondition> {}

extension OrderStatusTimestampsQuerySortBy
    on QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QSortBy> {
  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortByArrivedAtPickupPointAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'arrivedAtPickupPointAt', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortByArrivedAtPickupPointAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'arrivedAtPickupPointAt', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortByInTransitAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inTransitAt', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortByInTransitAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inTransitAt', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortByInvalidAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invalidAt', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortByInvalidAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invalidAt', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortByOrderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderId', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortByOrderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderId', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortByPaidAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAt', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortByPaidAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAt', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortByPendingDeliveryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingDeliveryAt', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortByPendingDeliveryAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingDeliveryAt', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortByPendingPaymentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingPaymentAt', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortByPendingPaymentAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingPaymentAt', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortByPendingShipmentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingShipmentAt', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortByPendingShipmentAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingShipmentAt', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortByReturnRefundAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'returnRefundAt', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortByReturnRefundAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'returnRefundAt', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortBySignedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signedAt', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      sortBySignedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signedAt', Sort.desc);
    });
  }
}

extension OrderStatusTimestampsQuerySortThenBy
    on QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QSortThenBy> {
  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenByArrivedAtPickupPointAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'arrivedAtPickupPointAt', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenByArrivedAtPickupPointAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'arrivedAtPickupPointAt', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenByInTransitAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inTransitAt', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenByInTransitAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inTransitAt', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenByInvalidAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invalidAt', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenByInvalidAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invalidAt', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenByOrderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderId', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenByOrderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderId', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenByPaidAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAt', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenByPaidAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAt', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenByPendingDeliveryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingDeliveryAt', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenByPendingDeliveryAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingDeliveryAt', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenByPendingPaymentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingPaymentAt', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenByPendingPaymentAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingPaymentAt', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenByPendingShipmentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingShipmentAt', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenByPendingShipmentAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingShipmentAt', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenByReturnRefundAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'returnRefundAt', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenByReturnRefundAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'returnRefundAt', Sort.desc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenBySignedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signedAt', Sort.asc);
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QAfterSortBy>
      thenBySignedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signedAt', Sort.desc);
    });
  }
}

extension OrderStatusTimestampsQueryWhereDistinct
    on QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QDistinct> {
  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QDistinct>
      distinctByArrivedAtPickupPointAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'arrivedAtPickupPointAt');
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QDistinct>
      distinctByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedAt');
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QDistinct>
      distinctByInTransitAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'inTransitAt');
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QDistinct>
      distinctByInvalidAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'invalidAt');
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QDistinct>
      distinctByOrderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderId');
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QDistinct>
      distinctByPaidAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paidAt');
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QDistinct>
      distinctByPendingDeliveryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pendingDeliveryAt');
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QDistinct>
      distinctByPendingPaymentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pendingPaymentAt');
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QDistinct>
      distinctByPendingShipmentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pendingShipmentAt');
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QDistinct>
      distinctByReturnRefundAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'returnRefundAt');
    });
  }

  QueryBuilder<OrderStatusTimestamps, OrderStatusTimestamps, QDistinct>
      distinctBySignedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'signedAt');
    });
  }
}

extension OrderStatusTimestampsQueryProperty on QueryBuilder<
    OrderStatusTimestamps, OrderStatusTimestamps, QQueryProperty> {
  QueryBuilder<OrderStatusTimestamps, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<OrderStatusTimestamps, DateTime?, QQueryOperations>
      arrivedAtPickupPointAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'arrivedAtPickupPointAt');
    });
  }

  QueryBuilder<OrderStatusTimestamps, DateTime?, QQueryOperations>
      completedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedAt');
    });
  }

  QueryBuilder<OrderStatusTimestamps, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<OrderStatusTimestamps, DateTime?, QQueryOperations>
      inTransitAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'inTransitAt');
    });
  }

  QueryBuilder<OrderStatusTimestamps, DateTime?, QQueryOperations>
      invalidAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'invalidAt');
    });
  }

  QueryBuilder<OrderStatusTimestamps, int, QQueryOperations> orderIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderId');
    });
  }

  QueryBuilder<OrderStatusTimestamps, DateTime?, QQueryOperations>
      paidAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paidAt');
    });
  }

  QueryBuilder<OrderStatusTimestamps, DateTime?, QQueryOperations>
      pendingDeliveryAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pendingDeliveryAt');
    });
  }

  QueryBuilder<OrderStatusTimestamps, DateTime?, QQueryOperations>
      pendingPaymentAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pendingPaymentAt');
    });
  }

  QueryBuilder<OrderStatusTimestamps, DateTime?, QQueryOperations>
      pendingShipmentAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pendingShipmentAt');
    });
  }

  QueryBuilder<OrderStatusTimestamps, DateTime?, QQueryOperations>
      returnRefundAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'returnRefundAt');
    });
  }

  QueryBuilder<OrderStatusTimestamps, DateTime?, QQueryOperations>
      signedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'signedAt');
    });
  }
}
