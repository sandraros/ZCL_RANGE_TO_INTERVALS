CLASS zcl_range_to_intervals__dattim DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES tr_date TYPE RANGE OF d.
    TYPES tr_time TYPE RANGE OF t.
    TYPES:
      BEGIN OF ts_interval,
        from_date   TYPE d,
        from_time   TYPE t,
        to_date     TYPE d,
        to_time     TYPE t,
        is_in_range TYPE abap_bool,
      END OF ts_interval.
    TYPES tt_interval TYPE SORTED TABLE OF ts_interval WITH UNIQUE KEY primary_key ALIAS by_from_date_and_time COMPONENTS from_date from_time.

    METHODS constructor
      IMPORTING ir_date TYPE tr_date
                ir_time TYPE tr_time.

    METHODS get_intervals
      RETURNING VALUE(rt_interval) TYPE tt_interval
      RAISING   zcx_range_to_intervals.

  PRIVATE SECTION.
    DATA gr_date    TYPE tr_date.
    DATA gr_time    TYPE tr_time.
ENDCLASS.


CLASS zcl_range_to_intervals__dattim IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    gr_date = ir_date.
    gr_time = ir_time.
  ENDMETHOD.

  METHOD get_intervals.
    DATA previous_interval TYPE REF TO ts_interval.

    DATA(lo_date_converter) = NEW zcl_range_to_intervals__date( gr_date ).
    DATA(lt_date_interval) = lo_date_converter->get_intervals( ).

    DATA(lo_time_converter) = NEW zcl_range_to_intervals__time( gr_time ).
    DATA(lt_time_interval) = lo_time_converter->get_intervals( ).

    LOOP AT lt_date_interval REFERENCE INTO DATA(ls_date_interval).
      LOOP AT lt_time_interval REFERENCE INTO DATA(ls_time_interval).
        DATA(ls_interval) = VALUE ts_interval( from_date   = ls_date_interval->from
                                               from_time   = ls_time_interval->from
                                               to_date     = ls_date_interval->to
                                               to_time     = ls_time_interval->to
                                               is_in_range = boolc(     ls_date_interval->from IN gr_date
                                                                    AND ls_time_interval->from IN gr_time ) ).
        " Either merge the interval with the previous one if they are both in range or both not in range
        " or insert a new interval
        IF     previous_interval       IS BOUND
           AND ls_interval-is_in_range  = previous_interval->is_in_range.
          previous_interval->to_date = ls_interval-to_date.
          previous_interval->to_time = ls_interval-to_time.
        ELSE.
          INSERT ls_interval INTO TABLE rt_interval REFERENCE INTO previous_interval.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
