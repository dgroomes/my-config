package dgroomes

import com.google.gson.GsonBuilder
import com.intellij.openapi.components.Service
import com.intellij.openapi.fileEditor.FileEditorManager
import com.intellij.openapi.ide.CopyPasteManager
import com.intellij.openapi.project.Project
import java.awt.datatransfer.StringSelection


/**
 * Copy file names of the open tabs in the current project to the clipboard as JSON.
 *
 * I'd like to extend this into a general: "Copy working details about project like open files, changed files, branch
 * name, etc.". Although I'm not really sure about the VCS stuff because that's not an IDE-specific thing.
 *
 * Maybe if I started using IntelliJ's bookmarks + notes, that's another useful context. Same for tasks, etc. But I
 * don't really want to get more coupled into the IDE. The purpose of this plugin is to eject from the IDE.
 *
 * For example:
 *
 * ```json
 * {
 *   "project_name": "intellij-playground",
 *   "project_base_path": "/Users/dave/repos/personal/intellij-playground",
 *   "open_files": [
 *     {
 *       "name": "README.md",
 *       "path": "/Users/dave/repos/personal/intellij-playground/README.md",
 *       "extension": "md"
 *     },
 *     {
 *       "name": "graphql.config.yml",
 *       "path": "/Users/dave/repos/personal/intellij-playground/graphql.config.yml",
 *       "extension": "yml"
 *     }
 *   ]
 * }
 * ```
 *
 */
@Service(Service.Level.PROJECT)
class CopyOpenTabsService(private val project: Project) {

    // The IntelliJ Platform uses Gson?? I don't understand which dependencies are available, and specifically which
    // are advertised to be available, which are "you technically can use them, but we can always remove them", and
    // which things are shaded and how the classloading works.
    private val gson = GsonBuilder().setPrettyPrinting().create();

    fun copyOpenTabNames() {
        val fileEditorManager = FileEditorManager.getInstance(project)
        val openFiles = fileEditorManager.openFiles
        val fileInfoList = openFiles.map {
            mapOf(
                "name" to it.name,
                "path" to it.path,
                "extension" to it.extension
            )
        }
        val projectInfo = mapOf(
            "project_name" to project.name,
            "project_base_path" to project.basePath,
            "open_files" to fileInfoList
        )

        val json = gson.toJson(projectInfo)
        CopyPasteManager.getInstance().setContents(StringSelection(json))
    }
}