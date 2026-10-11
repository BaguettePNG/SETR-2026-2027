# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "ADDR_LENGHT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DATA_LENGHT" -parent ${Page_0}


}

proc update_PARAM_VALUE.ADDR_LENGHT { PARAM_VALUE.ADDR_LENGHT } {
	# Procedure called to update ADDR_LENGHT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADDR_LENGHT { PARAM_VALUE.ADDR_LENGHT } {
	# Procedure called to validate ADDR_LENGHT
	return true
}

proc update_PARAM_VALUE.DATA_LENGHT { PARAM_VALUE.DATA_LENGHT } {
	# Procedure called to update DATA_LENGHT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_LENGHT { PARAM_VALUE.DATA_LENGHT } {
	# Procedure called to validate DATA_LENGHT
	return true
}


proc update_MODELPARAM_VALUE.ADDR_LENGHT { MODELPARAM_VALUE.ADDR_LENGHT PARAM_VALUE.ADDR_LENGHT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADDR_LENGHT}] ${MODELPARAM_VALUE.ADDR_LENGHT}
}

proc update_MODELPARAM_VALUE.DATA_LENGHT { MODELPARAM_VALUE.DATA_LENGHT PARAM_VALUE.DATA_LENGHT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_LENGHT}] ${MODELPARAM_VALUE.DATA_LENGHT}
}

