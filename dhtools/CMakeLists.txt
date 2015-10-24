# We distinguish executable and non-executable files
# The former are installed with execute permission.
# The latter are installed without execute permission.

LIST(APPEND exes declare_files.sh )
LIST(APPEND exes make_json_lbne.sh )
LIST(APPEND exes get_files.py )

# Non-executable python files.

LIST(APPEND nonexes example.json ) 

message(STATUS "Executable data handling scripts ${exes}")
message(STATUS "Non-executable data handling files ${nonexes}")

install(PROGRAMS ${exes} DESTINATION ${product}/${version}/dhtools)
install(FILES ${nonexes} DESTINATION ${product}/${version}/dhtools)
install_scripts(LIST ${exes})
