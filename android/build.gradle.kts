// build.gradle.kts (raíz de la carpeta android)

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("com.google.gms:google-services:4.3.15")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Esto soluciona conflictos de rutas de build
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Garantiza dependencias evaluadas correctamente
subprojects {
    project.evaluationDependsOn(":app")
}

// Tarea clean global
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}




