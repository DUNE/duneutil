FILE(GLOB xml_files *.xml)
install(FILES ${xml_files} DESTINATION ${product}/${version}/xml/mcc7.1)
install_source( EXTRAS ${xml_files} )
