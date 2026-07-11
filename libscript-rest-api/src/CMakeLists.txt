set(SOURCES
    main.c
)

add_executable(libscript-rest-api ${SOURCES})

# If c-rest-framework defines a target (e.g. c-rest-framework or crf), link it here.
# Assuming it defines a library target named `c-rest-framework`
if(TARGET c-rest-framework)
    target_link_libraries(libscript-rest-api PRIVATE c-rest-framework)
endif()

# System specific libraries
if(WIN32)
    target_link_libraries(libscript-rest-api PRIVATE ws2_32)
elseif(UNIX AND NOT APPLE)
    target_link_libraries(libscript-rest-api PRIVATE pthread m)
endif()
