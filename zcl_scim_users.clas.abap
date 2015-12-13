class ZCL_SCIM_USERS definition
  public
  inheriting from Y_ADL_RES_BASE
  create public .

public section.

  class-methods GET_XML_TIME
    importing
      !IV_DATE type DATUM default SY-DATUM
      !IV_TIME type UZEIT default SY-UZEIT
    returning
      value(RV_DATE_XML) type STRING .
  methods GET
    importing
      !MATCHES type STRINGTAB .
protected section.
private section.
ENDCLASS.



CLASS ZCL_SCIM_USERS IMPLEMENTATION.


  METHOD get.

    DATA: lt_userlist        TYPE hrbas_bapiusname_table,
          lv_number_of_users TYPE int4,
          lv_response        TYPE string.

    DATA: ls_admindata TYPE bapiuseradmin,
          lt_groups    TYPE TABLE OF bapiagr,
          lt_return    TYPE bapiret2_tab,
          lt_smtp      TYPE TABLE OF bapiadsmtp,
          lv_url       TYPE string.

    DATA: lv_firstuser  TYPE boolean,
          lv_firstmail  TYPE boolean,
          lv_firstgroup TYPE boolean.

    CALL FUNCTION 'BAPI_USER_GETLIST'
      EXPORTING
*       max_rows      =     " Maximum Number of Lines of Hits
        with_username = 'X'    " Read User with Name
*  IMPORTING
*       rows          =     " No. of users selected
      TABLES
*       selection_range =     " Search for Users with a Ranges Table
*       selection_exp =     " Search for Users with Free Selections
        userlist      = lt_userlist   " User List
*       return        =     " Return Parameter
      .

    lv_url = me->urlinfo-shp && me->urlinfo-prefix.

    CONSTANTS: c_tab TYPE c VALUE
             cl_abap_char_utilities=>cr_lf.

    me->response->set_header_field(
      name  = 'content-type'
      value = 'application/json'
    ).

    DESCRIBE TABLE lt_userlist LINES lv_number_of_users.
    lv_response =
    '{' &&
      '"totalResults":' && lv_number_of_users &&
      ',"schemas":["urn:scim:schemas:core:1.0"],' &&
      '"Resources":['.
    LOOP AT lt_userlist ASSIGNING FIELD-SYMBOL(<fs_user>).
      CLEAR: lv_firstmail, lv_firstgroup.
      CALL FUNCTION 'BAPI_USER_GET_DETAIL'
        EXPORTING
          username       = <fs_user>-username    " User Name
*         cache_results  = 'X'    " Temporarily buffer results in work process
        IMPORTING
*         logondata      =     " Structure with Logon Data
*         defaults       =     " Structure with User Defaults
*         address        =     " Address Data
*         company        =     " Company for Company Address
*         snc            =     " Secure Network Communication Data
*         ref_user       =     " User Name of the Reference User
*         alias          =     " User Name Alias
*         uclass         =     " License-Related User Classification
*         lastmodified   =     " User: Last Change (Date and Time)
*         islocked       =     " User Lock
*         identity       =     " Person Assignment of an Identity
          admindata      = ls_admindata    " User: Administration Data
        TABLES
*         parameter      =     " Table with User Parameters
*         profiles       =     " Profiles
          activitygroups = lt_groups    " Activity Groups
          return         = lt_return    " Return Structure
*         addtel         =     " BAPI Structure Telephone Numbers
*         addfax         =     " BAPI Structure Fax Numbers
*         addttx         =     " BAPI Structure Teletex Numbers
*         addtlx         =     " BAPI Structure Telex Numbers
          addsmtp        = lt_smtp    " E-Mail Addresses BAPI Structure
*         addrml         =     " Inhouse Mail BAPI Structure
*         addx400        =     " BAPI Structure X400 Addresses
*         addrfc         =     " BAPI Structure RFC Addresses
*         addprt         =     " BAPI Structure Printer Addresses
*         addssf         =     " BAPI Structure SSF Addresses
*         adduri         =     " BAPI Structure: URL, FTP, and so on
*         addpag         =     " BAPI Structure Pager Numbers
*         addcomrem      =     " BAPI Structure Communication Comments
*         parameter1     =     " Replaces Parameter (Length 18 -> 40)
*         groups         =     " Transfer Structure for a List of User Groups
*         uclasssys      =     " System-Specific License-Related User Classification
*         extidhead      =     " Header Data for External ID of a User
*         extidpart      =     " Part of a Long Field for the External ID of a User
*         systems        =     " BAPI Structure for CUA Target Systems
        .
      IF lv_firstuser = abap_true.
        lv_response = lv_response && ','.
      ELSE.
        lv_firstuser = abap_true.
      ENDIF.
      lv_response = lv_response &&
        '{' &&
          '"userName":"' && <fs_user>-username && '",' &&
          '"name":{' &&
            '"familyName":"' && <fs_user>-lastname  && '",' &&
            '"givenName":"'  && <fs_user>-firstname && '"'  &&
          '},' &&
          '"displayName":"' && <fs_user>-fullname && '",' &&
          '"emails":['.
      LOOP AT lt_smtp ASSIGNING FIELD-SYMBOL(<fs_smtp>).
        IF lv_firstmail = abap_true.
          lv_response = lv_response && ','.
        ELSE.
          lv_firstmail = abap_true.
        ENDIF.
        lv_response = lv_response &&
        '{"value":"' && <fs_smtp>-e_mail && '","primary":"true"}'.
      ENDLOOP.
      lv_response = lv_response && '],"groups":['.
      LOOP AT lt_groups ASSIGNING FIELD-SYMBOL(<fs_group>).
        IF lv_firstgroup = abap_true.
          lv_response = lv_response && ','.
        ELSE.
          lv_firstgroup = abap_true.
        ENDIF.
        lv_response = lv_response &&
        '{"value":"' && <fs_group>-agr_name &&
        '","display":"' && <fs_group>-agr_text &&
        '"}'.
      ENDLOOP.
      lv_response = lv_response && '],'.
      lv_response = lv_response &&
      '"externalId":"' && <fs_user>-username && '",' &&
      '"id":"' && <fs_user>-username && '",' &&
      '"meta":{"created":"' &&  zcl_scim_users=>get_xml_time(
                                    iv_date     = ls_admindata-erdat
                                    iv_time     = '000000'
                                ) && '",' &&
      '"lastModified":"' &&  zcl_scim_users=>get_xml_time(
                                    iv_date     = ls_admindata-erdat
                                    iv_time     = '000000'
                                ) && '",'.
      lv_response = lv_response &&
      '"location":"' && lv_url && '/Users/' && <fs_user>-username && '"}' &&
    '}'.
    ENDLOOP.
    lv_response = lv_response &&
    ']' &&
  '}'.

    me->response->set_cdata(
      EXPORTING
        data   = lv_response    " Character data
*        offset = 0    " Offset into character data
*        length = -1    " Length of character data
    ).
  ENDMETHOD.


  METHOD get_xml_time.

    DATA: l_xml_string TYPE string,
          l_dat_time   TYPE xsddatetime_z.

    l_dat_time = iv_date && iv_time.

    CALL TRANSFORMATION id
      SOURCE root = l_dat_time
      RESULT XML l_xml_string.

    CALL TRANSFORMATION id
      SOURCE XML l_xml_string
      RESULT root = rv_date_xml.

  ENDMETHOD.
ENDCLASS.