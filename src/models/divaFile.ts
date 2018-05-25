/**
 * Created by Marcel Würsch on 03.11.16.
 */

import * as nconf from "nconf";
import * as path from "path";
/**
 * class representing an internal data item
 * 
 * @export
 * @class DivaFile
 */
export class DivaFile {

    /**
     * the folder name of the file on the filesystem
     * 
     * @type {string}
     * @memberof File
     */
    public folder: string;
    /**
     * the name of the file
     * 
     * @type {string}
     * @memberof File
     */
    public filename: string;

    /**
     * the DIVAServices identifier of the file 
     * 
     * @type {string}
     * @memberof DivaFile
     */
    public identifier: string;

    /**
     * the name of the collection
     * @type {string}
     * @memberof File
     */
    public collection: string;

    /**
     * the file extension
     * 
     * @type {string}
     * @memberof File
     */
    public extension: string;
    /**
     * the full path to the data file
     * 
     * @type {string}
     * @memberof File
     */
    public path: string;

    /**
     * the public url to retrieve this file
     * 
     * @type {string}
     * @memberof DivaFile
     */
    public url: string;

    /**
     * Creates an instance of DivaFile.
     * @memberof DivaFile
     */
    constructor() {
        this.folder = "";
        this.filename = "";
        this.extension = "";
        this.path = "";
        this.identifier = "";
    }

    /**
     * Create a DivaFile for a specific data item in a collection
     * 
     * @static
     * @param {string} collection the collection containing the file
     * @param {string} filename  the filename of the file
     * @returns {DivaFile} The created DivaFile
     * @memberof DivaFile
     */
    static CreateFile(collection: string, filename: string): DivaFile {
        let item = new DivaFile();
        item.collection = collection;
        item.filename = filename;
        item.extension = filename.split(".").pop();
        item.path = nconf.get("paths:filesPath") + path.sep + collection + path.sep + "original" + path.sep + filename;
        item.identifier = item.path.replace(nconf.get("paths:filesPath") + path.sep, "").replace(path.sep + "original", "");
        item.url = "http://" + nconf.get("server:rootUrl") + "/files/" + collection + "/original/" + filename;
        return item;
    }
    /**
     * Create a DivaFile from a full path to the file
     * 
     * @static
     * @param {string} filePath The path to the file 
     * @returns {DivaFile} The created DivaFile
     * @memberof DivaFile
     */
    static CreateFileFull(filePath: string): DivaFile {
        let item = new DivaFile();
        let relativePath = filePath.replace(nconf.get("paths:filesPath") + path.sep, "");
        item.path = filePath;
        item.identifier = relativePath.replace(path.sep + "original", "");
        item.url = "http://" + nconf.get("server:rootUrl") + "/files/" + relativePath;
        item.filename = path.parse(filePath).base;
        item.extension = path.parse(filePath).ext;
        return item;

    }
    /**
     * Create a DivaFile used in testing with a full path to the file
     * 
     * @static
     * @param {string} filePath The path to the file
     * @returns {DivaFile} The created DivaFile
     * @memberof DivaFile
     */
    static CreateFileFullTest(filePath: string): DivaFile {
        let relativePath = filePath.replace(nconf.get("paths:executablePath") + path.sep, "");
        let item = new DivaFile();
        item.path = filePath;
        item.url = "http://" + nconf.get("server:rootUrl") + "/test/" + relativePath;
        item.filename = path.parse(filePath).base;
        item.extension = path.parse(filePath).ext;
        item.identifier = relativePath.replace(path.sep + "original", "");
        return item;
    }
}