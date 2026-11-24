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

subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android")
        if (androidExt != null) {
            try {
                val setCompileSdk = androidExt.javaClass.getMethod("setCompileSdk", Int::class.javaPrimitiveType)
                setCompileSdk.invoke(androidExt, 36)
            } catch (_: Exception) {
            }
            try {
                val compileSdkVersion = androidExt.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                compileSdkVersion.invoke(androidExt, 36)
            } catch (_: Exception) {
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
