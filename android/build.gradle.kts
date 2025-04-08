allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

//  올바른 Provider<Directory> 사용법
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build")

subprojects {
    val subBuildDir = newBuildDir.map { it.dir(project.name) }
    project.layout.buildDirectory.value(subBuildDir)
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
