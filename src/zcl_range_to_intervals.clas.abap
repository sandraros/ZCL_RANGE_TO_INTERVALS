CLASS zcl_range_to_intervals DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES tr_time TYPE RANGE OF t.
    TYPES:
      BEGIN OF ts_interval,
        from_time     TYPE t,
        to_time     TYPE t,
        is_in_range TYPE abap_bool,
      END OF ts_interval.
    TYPES tt_interval TYPE SORTED TABLE OF ts_interval WITH UNIQUE KEY primary_key ALIAS by_from_time COMPONENTS from_time.

    METHODS constructor
      IMPORTING ir_time TYPE tr_time.

    METHODS get_intervals
      retURNING VALUE(rt_interval) TYPE tt_interval.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ts_splitting,
        value_before TYPE t,
        value_after  TYPE t,
      END OF ts_splitting.
    TYPES tt_splitting TYPE SORTED TABLE OF ts_splitting WITH UNIQUE KEY primary_key ALIAS by_value_before COMPONENTS value_before.

    DATA splittings  TYPE tt_splitting.
    DATA gr_time TYPE tr_time.

    METHODS get_range_key_values
      RAISING lcx_range_invalid.

    METHODS split_at_v_and_v_plus_1
      IMPORTING v TYPE any.

    METHODS split_at_v_minus_1_and_v
      IMPORTING v TYPE any.

ENDCLASS.


CLASS zcl_range_to_intervals IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    gr_time = ir_time.
  ENDMETHOD.

  METHOD get_intervals.
    DATA previous_interval TYPE REF TO ts_interval.

    get_range_key_values( ).

    insert value #( value_before = '235959' ) into table splittings.

    DATA(interval) = VALUE ts_interval( from_time = '000000' ).

    LOOP AT splittings REFERENCE INTO DATA(splitting).
      " Build the interval
      interval-to_time     = splitting->value_before.
      interval-is_in_range = boolc( interval-from_time IN gr_time ).

      " Merge the interval with the previous one or insert a new one
      IF     previous_interval    IS BOUND
         AND interval-is_in_range  = previous_interval->is_in_range.
        previous_interval->to_time = interval-to_time.
      ELSE.
        INSERT interval INTO TABLE rt_interval REFERENCE INTO previous_interval.
      ENDIF.

      interval = VALUE #( from_time = splitting->value_after ).
    ENDLOOP.

*    interval-to_time     = '235959'.
*    interval-is_in_range = boolc( interval-from_time IN gr_time ).
*    INSERT interval INTO TABLE rt_interval.
  ENDMETHOD.

  METHOD split_at_v_and_v_plus_1.
    DATA(splitting) = VALUE ts_splitting( value_before = v ).
    IF splitting-value_before <> '235959'.
      splitting-value_after = splitting-value_before + 1.
    ENDIF.
    INSERT splitting INTO TABLE splittings.
  ENDMETHOD.

  METHOD split_at_v_minus_1_and_v.
    DATA(splitting) = VALUE ts_splitting( value_after = v ).
    IF splitting-value_after <> '000000'.
      splitting-value_before = splitting-value_after - 1.
    ENDIF.
    INSERT splitting INTO TABLE splittings.
  ENDMETHOD.

  METHOD get_range_key_values.
*    DATA line_of_ranges_table TYPE REF TO data.
*    DATA range_key_value      TYPE REF TO data.

*    FIELD-SYMBOLS <lt_range_key_value> TYPE STANDARD TABLE.
*
*    CREATE DATA line_of_ranges_table LIKE LINE OF any_ranges_table.
*    ASSIGN line_of_ranges_table->* TO FIELD-SYMBOL(<line_of_ranges_table>).
*    ASSIGN COMPONENT 3 OF STRUCTURE <line_of_ranges_table> TO FIELD-SYMBOL(<low>).
*    ASSERT sy-subrc = 0.
*    CREATE DATA rt_range_key_value LIKE STANDARD TABLE OF <low>.
*    ASSIGN rt_range_key_value->* TO <lt_range_key_value>.
*    CREATE DATA range_key_value LIKE <low>.
*    ASSIGN range_key_value->* TO FIELD-SYMBOL(<range_key_value>).

    LOOP AT gr_time ASSIGNING FIELD-SYMBOL(<line_of_ranges_table>).
*    LOOP AT any_ranges_table ASSIGNING <line_of_ranges_table>.
      ASSIGN COMPONENT 2 OF STRUCTURE <line_of_ranges_table> TO FIELD-SYMBOL(<option>).
      ASSERT sy-subrc = 0.
      ASSIGN COMPONENT 3 OF STRUCTURE <line_of_ranges_table> TO FIELD-SYMBOL(<low>).
      ASSERT sy-subrc = 0.
      ASSIGN COMPONENT 4 OF STRUCTURE <line_of_ranges_table> TO FIELD-SYMBOL(<high>).
      ASSERT sy-subrc = 0.

      "        V-1 V V+1 W-1 W W+1
      " BT V W  F  T  T   T  T  F
      " CP V++  T  F  T
      " CP V*1  T  F  T
      " EQ V    F  T  F
      " GE V    F  T  T
      " GT V    F  F  T
      " LE V    T  T  F
      " LT V    T  F  F
      " NB V W  T  F  F   F  F  T
      " NE V    T  F  T
      " NP V++  F  T  F
      " NP V*1  F  T  F
      CASE <option>.
        WHEN 'BT' OR 'NB'.
          split_at_v_minus_1_and_v( v = <low> ).
          split_at_v_and_v_plus_1( v = <high> ).
        WHEN 'CP' OR 'NP'.
          " TODO
        WHEN 'EQ' OR 'NE'.
          split_at_v_minus_1_and_v( <low> ).
          split_at_v_and_v_plus_1( <low> ).
        WHEN 'GE'.
          split_at_v_minus_1_and_v( v = <low> ).
        WHEN 'GT'.
          split_at_v_and_v_plus_1( v = <low> ).
        WHEN 'LE'.
          split_at_v_and_v_plus_1( v = <low> ).
        WHEN 'LT'.
          split_at_v_minus_1_and_v( v = <low> ).
        WHEN OTHERS.
          RAISE EXCEPTION TYPE lcx_range_invalid.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
