allprojects {
    repositories {
        maven { url = uri("https://maven.myket.ir/") }
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    buildscript {
        repositories {
            maven { url = uri("https://maven.myket.ir/") }
            google()
            mavenCentral()
        }
    }

    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// isar_flutter_libs 3.1.0+1 is outdated for AGP 8+ (missing namespace, compileSdk 30)
subprojects {
    if (name == "isar_flutter_libs") {
        pluginManager.withPlugin("com.android.library") {
            extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
                namespace = "dev.isar.isar_flutter_libs"
            }
        }
        afterEvaluate {
            extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
                compileSdk = 36
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
