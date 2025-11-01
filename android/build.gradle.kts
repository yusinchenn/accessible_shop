// File: android/build.gradle.kts

// 為所有子模組設置通用倉庫
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 修正 build 資料夾結構（Flutter 預設）
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 為第三方 Android library（如 isar_flutter_libs）自動補 namespace
subprojects {
    // 先配置所有項目，使用 SDK 36
    afterEvaluate {
        extensions.findByType<com.android.build.gradle.LibraryExtension>()?.apply {
            compileSdk = 36
            println("Force set compileSdk=36 for ${project.name}")
        }
    }

    plugins.withId("com.android.library") {
        configure<com.android.build.gradle.LibraryExtension> {
            // 強制設置 compileSdk 為 36
            compileSdk = 36

            if (namespace == null) {
                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val manifest = manifestFile.readText()
                    val regex = """package\s*=\s*["']([^"']+)["']""".toRegex()
                    val match = regex.find(manifest)
                    if (match != null) {
                        namespace = match.groupValues[1]
                        println("Auto-set namespace for ${project.name}: ${namespace}")
                    }
                }
            }

            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_11
                targetCompatibility = JavaVersion.VERSION_11
            }
        }
    }

    tasks.withType<JavaCompile> {
        options.compilerArgs.add("-Xlint:-options")
        sourceCompatibility = "11"
        targetCompatibility = "11"
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
