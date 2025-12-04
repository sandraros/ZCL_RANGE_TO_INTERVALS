CLASS zcl_range_to_intervals DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS convert
      IMPORTING any_ranges_table TYPE STANDARD TABLE
      EXPORTING !intervals       TYPE SORTED TABLE
      RAISING   zcx_range_to_intervals.

  PRIVATE SECTION.
    CLASS-METHODS get_ranges_table_base_type
      IMPORTING rtti             TYPE REF TO cl_abap_typedescr
      RETURNING VALUE(base_type) TYPE REF TO cl_abap_typedescr.

    CLASS-METHODS is_ranges_table
      IMPORTING rtti            TYPE REF TO cl_abap_typedescr
      RETURNING VALUE(is_range) TYPE abap_bool.

    CLASS-METHODS is_ranges_table_line
      IMPORTING rtti                 TYPE REF TO cl_abap_typedescr
      RETURNING VALUE(is_range_line) TYPE abap_bool.
ENDCLASS.


CLASS zcl_range_to_intervals IMPLEMENTATION.
  METHOD convert.
    DATA(lo_ranges_table_typedescr) = cl_abap_typedescr=>describe_by_data( any_ranges_table ).
    IF abap_false = is_ranges_table( lo_ranges_table_typedescr ).
      RAISE EXCEPTION TYPE zcx_range_to_intervals
        EXPORTING
          textid = zcx_range_to_intervals=>invalid_ranges_table.
    ENDIF.

    DATA(lo_ranges_table_base_type) = get_ranges_table_base_type( lo_ranges_table_typedescr ).
    CASE lo_ranges_table_base_type->type_kind.
      WHEN lo_ranges_table_base_type->typekind_date.
        DATA(lo_date_converter) = NEW zcl_range_to_intervals__date( any_ranges_table ).
        intervals = lo_date_converter->get_intervals( ).
      WHEN lo_ranges_table_base_type->typekind_time.
        DATA(lo_time_converter) = NEW zcl_range_to_intervals__time( any_ranges_table ).
        intervals = lo_time_converter->get_intervals( ).
      WHEN OTHERS.
        RAISE EXCEPTION TYPE zcx_range_to_intervals
          EXPORTING
            textid = zcx_range_to_intervals=>base_type_not_supported.
    ENDCASE.
  ENDMETHOD.

  METHOD get_ranges_table_base_type.
    DATA rtti_tab TYPE REF TO cl_abap_tabledescr.
    DATA rtti_str TYPE REF TO cl_abap_structdescr.

    FIELD-SYMBOLS <comp> TYPE abap_compdescr.
    FIELD-SYMBOLS <low>  TYPE abap_compdescr.
    FIELD-SYMBOLS <high> TYPE abap_compdescr.

    CLEAR base_type.
    " Parameter MUST BE either CL_ABAP_TABLEDESCR, with lines of type CL_ABAP_STRUCTDESCR
    "                       or CL_ABAP_STRUCTDESCR.
    TRY.
        rtti_tab ?= rtti.
        rtti_str ?= rtti_tab->get_table_line_type( ).
      CATCH cx_sy_move_cast_error.
        " Not CL_ABAP_TABLEDESCR, try CL_ABAP_STRUCTDESCR
        TRY.
            rtti_str ?= rtti.
          CATCH cx_sy_move_cast_error.
            " Not even CL_ABAP_STRUCTDESCR
            RETURN.
        ENDTRY.
    ENDTRY.

    " Line must have 4 components
    IF lines( rtti_str->components ) <> 4.
      RETURN.
    ENDIF.

    READ TABLE rtti_str->components INDEX 1 ASSIGNING <comp>.
    IF <comp>-type_kind <> cl_abap_typedescr=>typekind_char.
      RETURN.
    ENDIF.
    IF <comp>-length <> 1 * cl_abap_char_utilities=>charsize.
      RETURN.
    ENDIF.

    READ TABLE rtti_str->components INDEX 2 ASSIGNING <comp>.
    IF <comp>-type_kind <> cl_abap_typedescr=>typekind_char.
      RETURN.
    ENDIF.
    IF <comp>-length <> 2 * cl_abap_char_utilities=>charsize.
      RETURN.
    ENDIF.

    READ TABLE rtti_str->components INDEX 3 ASSIGNING <low>.
    READ TABLE rtti_str->components INDEX 4 ASSIGNING <high>.
    IF <low>-type_kind <> <high>-type_kind.
      RETURN.
    ENDIF.
    IF <low>-length <> <high>-length.
      RETURN.
    ENDIF.
    base_type = rtti_str->get_component_type( p_name = <low>-name ).
  ENDMETHOD.

  METHOD is_ranges_table.
    DATA rtti_tab  TYPE REF TO cl_abap_tabledescr.
    DATA rtti_line TYPE REF TO cl_abap_typedescr.

    is_range = abap_false.

    TRY.
        " s'assurer que le type est un type de table
        rtti_tab ?= rtti.
        " récupérer le type de ligne du type de table
        rtti_line = rtti_tab->get_table_line_type( ).
        " s'assurer que le type de ligne est une ligne de range
        is_range = is_ranges_table_line( rtti_line ).
      CATCH cx_sy_move_cast_error.
        RETURN.
    ENDTRY.
  ENDMETHOD.

  METHOD is_ranges_table_line.
    DATA rtti_str TYPE REF TO cl_abap_structdescr.
    DATA lt_comp  TYPE cl_abap_structdescr=>component_table.

    FIELD-SYMBOLS <sign>   TYPE abap_componentdescr.
    FIELD-SYMBOLS <option> TYPE abap_componentdescr.
    FIELD-SYMBOLS <low>    TYPE abap_componentdescr.
    FIELD-SYMBOLS <high>   TYPE abap_componentdescr.

    is_range_line = abap_false.

    TRY.
        " s'assurer que le type est une structure
        rtti_str ?= rtti.
      CATCH cx_sy_move_cast_error.
        RETURN.
    ENDTRY.

    IF lines( rtti_str->components ) <> 4.
      RETURN.
    ENDIF.

    " TODO: variable is never used (ABAP cleaner)
    FIELD-SYMBOLS <ls_comp> TYPE LINE OF cl_abap_structdescr=>component_table.

    lt_comp = rtti_str->get_components( ).
    READ TABLE lt_comp INDEX 1 ASSIGNING <sign>.
    READ TABLE lt_comp INDEX 2 ASSIGNING <option>.
    READ TABLE lt_comp INDEX 3 ASSIGNING <low>.
    READ TABLE lt_comp INDEX 4 ASSIGNING <high>.

    IF <sign>-name <> 'SIGN'.
      RETURN.
    ENDIF.
    IF <sign>-type->type_kind <> cl_abap_typedescr=>typekind_char.
      RETURN.
    ENDIF.
    IF <sign>-type->length <> 1 * cl_abap_char_utilities=>charsize.
      RETURN.
    ENDIF.
    IF <option>-name <> 'OPTION'.
      RETURN.
    ENDIF.
    IF <option>-type->type_kind <> cl_abap_typedescr=>typekind_char.
      RETURN.
    ENDIF.
    IF <option>-type->length <> 2 * cl_abap_char_utilities=>charsize.
      RETURN.
    ENDIF.
    IF <low>-name <> 'LOW'.
      RETURN.
    ENDIF.
    IF <high>-name <> 'HIGH'.
      RETURN.
    ENDIF.
    IF <low>-type <> <high>-type.
      RETURN.
    ENDIF.

    is_range_line = abap_true.
  ENDMETHOD.
ENDCLASS.
