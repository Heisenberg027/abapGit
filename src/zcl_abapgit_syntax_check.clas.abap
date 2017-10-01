CLASS zcl_abapgit_syntax_check DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-METHODS run
      IMPORTING
        !iv_package    TYPE devclass
      RETURNING
        VALUE(rt_list) TYPE scit_alvlist .
  PROTECTED SECTION.

    CLASS-METHODS create_inspection
      IMPORTING
        !io_set              TYPE REF TO cl_ci_objectset
        !io_variant          TYPE REF TO cl_ci_checkvariant
      RETURNING
        VALUE(ro_inspection) TYPE REF TO cl_ci_inspection .
    CLASS-METHODS create_objectset
      IMPORTING
        !iv_package   TYPE devclass
      RETURNING
        VALUE(ro_set) TYPE REF TO cl_ci_objectset .
    CLASS-METHODS create_variant
      RETURNING
        VALUE(ro_variant) TYPE REF TO cl_ci_checkvariant .
    CLASS-METHODS run_inspection
      IMPORTING
        !io_inspection TYPE REF TO cl_ci_inspection
      RETURNING
        VALUE(rt_list) TYPE scit_alvlist .
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_ABAPGIT_SYNTAX_CHECK IMPLEMENTATION.


  METHOD create_inspection.

    cl_ci_inspection=>create(
      EXPORTING
        p_user           = sy-uname
        p_name           = ''
      RECEIVING
        p_ref            = ro_inspection
      EXCEPTIONS
        locked           = 1
        error_in_enqueue = 2
        not_authorized   = 3
        OTHERS           = 4 ).
    ASSERT sy-subrc = 0.

    ro_inspection->set(
      p_chkv = io_variant
      p_objs = io_set ).

  ENDMETHOD.


  METHOD create_objectset.

    DATA: lt_objs     TYPE scit_objs,
          lt_packages TYPE cl_pak_package_queries=>tt_subpackage_info,
          ls_package  LIKE LINE OF lt_packages,
          ls_obj      LIKE LINE OF lt_objs.


    cl_pak_package_queries=>get_all_subpackages(
      EXPORTING
        im_package             = iv_package
        im_also_local_packages = abap_true
      IMPORTING
        et_subpackages         = lt_packages ).

    ls_package-package = iv_package.
    INSERT ls_package INTO TABLE lt_packages.

    IF lines( lt_packages ) = 0.
      RETURN.
    ENDIF.

    SELECT object AS objtype obj_name AS objname
      FROM tadir
      INTO CORRESPONDING FIELDS OF TABLE lt_objs
      FOR ALL ENTRIES IN lt_packages
      WHERE devclass = lt_packages-package
      AND pgmid = 'R3TR'.                               "#EC CI_GENBUFF

    ro_set = cl_ci_objectset=>save_from_list( lt_objs ).

  ENDMETHOD.


  METHOD create_variant.

    DATA: lt_variant TYPE sci_tstvar,
          ls_variant LIKE LINE OF lt_variant.


    cl_ci_checkvariant=>create(
      EXPORTING
        p_user              = sy-uname
      RECEIVING
        p_ref               = ro_variant
      EXCEPTIONS
        chkv_already_exists = 1
        locked              = 2
        error_in_enqueue    = 3
        not_authorized      = 4
        OTHERS              = 5 ).
    ASSERT sy-subrc = 0.

    ls_variant-testname = 'CL_CI_TEST_SYNTAX_CHECK'.
    INSERT ls_variant INTO TABLE lt_variant.

    ro_variant->set_variant(
      EXPORTING
        p_variant    = lt_variant
      EXCEPTIONS
        not_enqueued = 1
        OTHERS       = 2 ).
    ASSERT sy-subrc = 0.

  ENDMETHOD.


  METHOD run.

    DATA: lo_set        TYPE REF TO cl_ci_objectset,
          lo_inspection TYPE REF TO cl_ci_inspection,
          lo_variant    TYPE REF TO cl_ci_checkvariant.


    lo_set = create_objectset( iv_package ).
    lo_variant = create_variant( ).

    lo_inspection = create_inspection(
      io_set     = lo_set
      io_variant = lo_variant ).

    rt_list = run_inspection( lo_inspection ).

  ENDMETHOD.


  METHOD run_inspection.

    io_inspection->run(
      EXCEPTIONS
        invalid_check_version = 1
        OTHERS                = 2 ).
    ASSERT sy-subrc = 0.

    io_inspection->plain_list(
      IMPORTING
        p_list = rt_list ).

  ENDMETHOD.
ENDCLASS.