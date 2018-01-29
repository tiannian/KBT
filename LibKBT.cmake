include(${KBT_VAR_TOOLS_DIR}/lib/init.cmake)
KBT_FUNC_INIT()
macro(KBT_SET_ARCH)
    if(NOT KBT_ARCH)
        set(KBT_ARCH ${ARGV0})
        set(CMAKE_SYSTEM_PROCESSOR ${ARGV0})
    endif()
endmacro()

macro(KBT_SET_PLATFORM)
    file(GLOB KBT_VAR_FILE_EXISTS ${KBT_VAR_TOOLS_DIR}/platform/${ARGV0}.cmake)
    if(NOT KBT_VAR_FILE_EXISTS)
        message(FATAL_ERROR "Specified platform does not exist. Please check detail in project github pages.")
    endif()
    if(NOT KBT_PLATFORM)
        set(KBT_PLATFORM ${ARGV0})
        # set(CMAKE_SYSTEM_NAME ${ARGV0})
        include(${KBT_VAR_TOOLS_DIR}/platform/${KBT_PLATFORM}.cmake)
    endif()
endmacro()

macro(KBT_SET_PROJECT_TYPE)
    if(NOT KBT_${PROJECT_NAME}_TYPE)
        string(TOUPPER ${PROJECT_NAME} KBT_VAR_PROJECT)
        set(KBT_${KBT_VAR_PROJECT}_TYPE ${ARGV0})
        if(KBT_${KBT_VAR_PROJECT}_TYPE STREQUAL "lib")
            list(APPEND LIB_DEPENDENTICES ${PROJECT_NAME})
        endif()
    endif()
endmacro()

macro(KBT_ADD_DEPENDENTICES)
    file(GLOB KBT_VAR_DEPENDIENCE_EXISTS "${CMAKE_SOURCE_DIR}/dependenices/${ARGV0}-${ARGV1}")
    # check remote repo version and exist
    if(NOT KBT_VAR_DEPENDIENCE_EXISTS)
        string(REGEX REPLACE [/] ";" KBT_VAR_DEP ${ARGV0})
        list(GET KBT_VAR_DEP 0 KBT_VAR_PARENT)
        list(GET KBT_VAR_DEP 1 KBT_VAR_DEP_NAME)
        file(MAKE_DIRECTORY ${CMAKE_SOURCE_DIR}/dependenices/${KBT_VAR_PARENT})
        message("Download dependenices ${ARGV0}-${ARGV1} from github")
        execute_process(COMMAND curl https://codeload.github.com/${ARGV0}/tar.gz/${ARGV1} 
            COMMAND tar -zx WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/dependenices/${KBT_VAR_PARENT})
        file(COPY ${CMAKE_SOURCE_DIR}/dependenices/${ARGV0}-${ARGV1}/include DESTINATION ${CMAKE_BINARY_DIR}/include/${KBT_VAR_PARENT})
        file(RENAME ${CMAKE_BINARY_DIR}/include/${KBT_VAR_PARENT}/include ${CMAKE_BINARY_DIR}/include/${ARGV0})
    endif()
    add_subdirectory("${CMAKE_SOURCE_DIR}/dependenices/${ARGV0}-${ARGV1}" ${CMAKE_BINARY_DIR}/dependenices/${ARGV0}-${ARGV1})
    # include_directories("${CMAKE_BINARY_DIR}/include")
endmacro()

macro(KBT_CONFIG)
    enable_language(C)
    file(GLOB KBT_VAR_CONFIG_EXISTS ${PROJECT_SOURCE_DIR}/${PROJECT_NAME}.config)
    if(NOT KBT_VAR_CONFIG_EXISTS)
        # Create test file
        file(WRITE  "${PROJECT_SOURCE_DIR}/${PROJECT_NAME}.config" "#cmakedefine KBT_PROJECT_NAME ${PROJECT_NAME}\n" )
        file(APPEND "${PROJECT_SOURCE_DIR}/${PROJECT_NAME}.config" "#cmakedefine KBT_ARCH ${KBT_ARCH}\n")
        file(APPEND "${PROJECT_SOURCE_DIR}/${PROJECT_NAME}.config" "#cmakedefine KBT_PLATFORM ${KBT_PLATFORM}\n")
        file(APPEND "${PROJECT_SOURCE_DIR}/${PROJECT_NAME}.config" "#cmakedefine KBT_${KBT_VAR_PROJECT}_TYPE ${KBT_${KBT_VAR_PROJECT}_TYPE}\n")
    endif()
    configure_file("${PROJECT_SOURCE_DIR}/${PROJECT_NAME}.config" ${PROJECT_SOURCE_DIR}/include/${PROJECT_NAME}.config.h)
    # Scan all source file
    file(GLOB_RECURSE KBT_VAR_SOURCES_FILES_LIST "${PROJECT_SOURCE_DIR}/src/*.c")
    if(KBT_VAR_SOURCES_FILES_LIST)
        # include_directories(${CMAKE_SOURCE_DIR}/include)
        include_directories(${PROJECT_SOURCE_DIR}/include)
        include_directories(${CMAKE_BINARY_DIR}/include)
        if(KBT_${KBT_VAR_PROJECT}_TYPE STREQUAL "lib")
            add_library(${PROJECT_NAME} STATIC ${KBT_VAR_SOURCES_FILES_LIST})
        endif()
        # Build bin project
        if(KBT_${KBT_VAR_PROJECT}_TYPE STREQUAL "bin")
            add_executable(${PROJECT_NAME} ${KBT_VAR_SOURCES_FILES_LIST})
            if (LIB_DEPENDENTICES)
                list(REMOVE_DUPLICATES LIB_DEPENDENTICES)
                target_link_libraries(${PROJECT_NAME} ${LIB_DEPENDENTICES})
            endif()
        endif()
    endif()
endmacro()
