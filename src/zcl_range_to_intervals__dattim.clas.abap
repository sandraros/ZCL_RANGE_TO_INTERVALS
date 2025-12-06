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
      IMPORTING ir_filter_date       TYPE tr_date OPTIONAL
                iv_maximum_iterations TYPE i       DEFAULT 10
      RETURNING VALUE(rt_interval)   TYPE tt_interval
      RAISING   zcx_range_to_intervals.

  PRIVATE SECTION.
    DATA gr_date TYPE tr_date.
    DATA gr_time TYPE tr_time.

    CLASS-METHODS truncate_date_intervals
      IMPORTING it_date_interval        TYPE zcl_range_to_intervals__date=>tt_interval
                ir_filter_date          TYPE zcl_range_to_intervals__date=>tr_date
      RETURNING VALUE(rt_date_interval) TYPE zcl_range_to_intervals__date=>tt_interval.

ENDCLASS.


CLASS zcl_range_to_intervals__dattim IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    gr_date = ir_date.
    gr_time = ir_time.
  ENDMETHOD.

  METHOD get_intervals.
    DATA lv_date           TYPE d.
    DATA previous_interval TYPE REF TO ts_interval.

    DATA(lo_date_converter) = NEW zcl_range_to_intervals__date( gr_date ).
    DATA(lt_date_interval) = lo_date_converter->get_intervals( ).

    DATA(lo_time_converter) = NEW zcl_range_to_intervals__time( gr_time ).
    DATA(lt_time_interval) = lo_time_converter->get_intervals( ).

    IF     lines( lt_time_interval )  = 1
       AND lt_time_interval[ 1 ]-from = '000000'
       AND lt_time_interval[ 1 ]-to   = '235959'.

      rt_interval = VALUE #( FOR <ls_date_interval> IN lt_date_interval
                             ( from_date   = <ls_date_interval>-from
                               from_time   = lt_time_interval[ 1 ]-from
                               to_date     = <ls_date_interval>-to
                               to_time     = lt_time_interval[ 1 ]-to
                               is_in_range = COND #( WHEN lt_time_interval[ 1 ]-is_in_range = abap_true
                                                     THEN <ls_date_interval>-is_in_range
                                                     ELSE abap_false ) ) ).
    ELSE.

      lt_date_interval = truncate_date_intervals( it_date_interval = lt_date_interval
                                                  ir_filter_date   = ir_filter_date ).

      DATA(lv_current_iterations) = 0.
      LOOP AT lt_date_interval REFERENCE INTO DATA(ls_date_interval).
        lv_date = ls_date_interval->from.
        WHILE lv_date <= ls_date_interval->to.
          LOOP AT lt_time_interval REFERENCE INTO DATA(ls_time_interval).
            DATA(ls_interval) = VALUE ts_interval( from_date   = lv_date " ls_date_interval->from
                                                   from_time   = ls_time_interval->from
                                                   to_date     = lv_date " ls_date_interval->to
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
*              " Note: the test to leave the method is before INSERT because TO_DATE and TO_TIME of the last inserted interval may need to be adjusted.
*              IF     iv_maximum_intervals >= 1
*                 AND lines( rt_interval )  >= iv_maximum_intervals.
*                RETURN.
*              ENDIF.
              INSERT ls_interval INTO TABLE rt_interval REFERENCE INTO previous_interval.
            ENDIF.
            lv_current_iterations = lv_current_iterations + 1.
            IF     iv_maximum_iterations >= 1
               AND lv_current_iterations >= iv_maximum_iterations.
                RETURN.
              ENDIF.
          ENDLOOP.
          lv_date = lv_date + 1.
        ENDWHILE.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD truncate_date_intervals.
    DATA lv_tabix_date_interval         TYPE i.
    DATA lv_tabix_based_on_date_interva TYPE i.
    DATA ls_date_interval               TYPE REF TO zcl_range_to_intervals__date=>ts_interval.
    DATA ls_based_on_date_interval      TYPE REF TO zcl_range_to_intervals__date=>ts_interval.
    DATA ls_result_date_interval        TYPE zcl_range_to_intervals__date=>ts_interval.

    DATA(lo_filter_date_converter) = NEW zcl_range_to_intervals__date( ir_filter_date ).
    DATA(lt_filter_date_interval) = lo_filter_date_converter->get_intervals( ).

    lv_tabix_date_interval = 0.
    lv_tabix_based_on_date_interva = 0.
    DO.

      " Read next interval(s)
      IF ls_date_interval IS NOT BOUND.
        lv_tabix_date_interval = lv_tabix_date_interval + 1.
        ls_date_interval = REF #( it_date_interval[ lv_tabix_date_interval ] OPTIONAL ).
      ENDIF.
      IF ls_based_on_date_interval IS NOT BOUND.
        lv_tabix_based_on_date_interva = lv_tabix_based_on_date_interva + 1.
        LOOP AT lt_filter_date_interval REFERENCE INTO ls_based_on_date_interval
             FROM lv_tabix_based_on_date_interva
             WHERE is_in_range = abap_true.
          lv_tabix_based_on_date_interva = sy-tabix.
          EXIT.
        ENDLOOP.
      ENDIF.

      IF    ls_date_interval          IS NOT BOUND
         OR ls_based_on_date_interval IS NOT BOUND.
        EXIT.
      ENDIF.

      IF     ls_date_interval->from <= ls_based_on_date_interval->to
         AND ls_date_interval->to   >= ls_based_on_date_interval->from.
        CLEAR ls_result_date_interval.
        IF ls_date_interval->from <= ls_based_on_date_interval->from.
          ls_result_date_interval-from = ls_based_on_date_interval->from.
        ELSE.
          ls_result_date_interval-from = ls_date_interval->from.
        ENDIF.
        IF ls_date_interval->to <= ls_based_on_date_interval->to.
          ls_result_date_interval-to = ls_date_interval->to.
        ELSE.
          ls_result_date_interval-to = ls_based_on_date_interval->to.
        ENDIF.
        ls_result_date_interval-is_in_range = ls_date_interval->is_in_range.
        INSERT ls_result_date_interval INTO TABLE rt_date_interval.
      ENDIF.

      " Which next interval to read?
      IF ls_date_interval->to = ls_based_on_date_interval->to.
        CLEAR ls_date_interval.
        CLEAR ls_based_on_date_interval.
      ELSEIF ls_date_interval->to < ls_based_on_date_interval->to.
        CLEAR ls_date_interval.
      ELSEIF ls_date_interval->to > ls_based_on_date_interval->to.
        CLEAR ls_based_on_date_interval.
      ENDIF.
    ENDDO.
  ENDMETHOD.
ENDCLASS.
