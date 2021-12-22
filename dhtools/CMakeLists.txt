# We distinguish executable and non-executable files
# The former are installed with execute permission.
# The latter are installed without execute permission.

LIST(APPEND exes declare_files.sh )
LIST(APPEND exes make_json_lbne.sh )
LIST(APPEND exes get_files.py )
LIST(APPEND exes dtr35t1.sh )
LIST(APPEND exes dtranslog35t.sh )
LIST(APPEND exes make_metadata35t_declare.sh )
LIST(APPEND exes daq6deleter.sh )
LIST(APPEND exes gwtdeleter.sh )
LIST(APPEND exes senv.sh )
LIST(APPEND exes iceberg_metadata.sh )

# Non-executable python files.

LIST(APPEND nonexes example.json ) 
LIST(APPEND nonexes example2.json ) 

message(STATUS "Executable data handling scripts ${exes}")
message(STATUS "Non-executable data handling files ${nonexes}")

install(PROGRAMS ${exes} DESTINATION dhtools)
install(FILES ${nonexes} DESTINATION dhtools)
install_scripts(LIST ${exes})
