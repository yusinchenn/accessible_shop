allprojects {
    repositories {
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
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 修復第三方套件（如 isar_flutter_libs）缺少 namespace 的問題
// 使用 plugins.withId 在插件應用時立即處理，而不是在 afterEvaluate 中
subprojects {
    plugins.withId("com.android.library") {
        configure<com.android.build.gradle.LibraryExtension> {
            // 設置 namespace（如果缺失）
            if (namespace == null) {
                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val manifest = manifestFile.readText()
                    val packageRegex = """package\s*=\s*["']([^"']+)["']""".toRegex()
                    val matchResult = packageRegex.find(manifest)
                    if (matchResult != null) {
                        namespace = matchResult.groupValues[1]
                        println("Auto-set namespace for ${project.name}: ${matchResult.groupValues[1]}")
                    }
                }
            }

            // 統一設置 Java 版本為 11，避免 Java 8 過時警告
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_11
                targetCompatibility = JavaVersion.VERSION_11
            }
        }
    }

    // 為所有專案設置 Java 編譯選項，抑制過時警告
    tasks.withType<JavaCompile> {
        options.compilerArgs.add("-Xlint:-options")
        sourceCompatibility = "11"
        targetCompatibility = "11"
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
