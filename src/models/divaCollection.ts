/**
 * Created by Marcel Würsch on 03.11.16.
 */

import * as nconf from "nconf";
import * as path from "path";

/**
 * class representing an internal data item
 * 
 * @export
 * @class DivaCollection
 */
export class DivaCollection {

    /**
     * the folder name of the file on the filesystem
     * 
     * @type {string}
     * @memberof File
     */
    public folder: string;

    /**
     * the name of the collection
     * @type {string}
     * @memberof File
     */
    public collection: string;

    /**
     * the public url to retrieve this file
     * 
     * @type {string}
     * @memberof DivaCollection
     */
    public url: string;

    /**
     * The URL to download a zip file from a collection
     * 
     * @type {string}
     * @memberof DivaCollection
     */
    public zipUrl: string;

    /**
     * Creates an instance of DivaCollection.
     * @memberof DivaCollection
     */
    constructor() {
        this.folder = "";
        this.collection = "";
        this.url = "";
        this.zipUrl;
    }

    /**
     * Create a DivaCollection from a the collection name
     * 
     * @static
     * @param {string} collection The name of the collection
     * @returns {DivaCollection} The created DivaCollection
     * @memberof DivaCollection
     */
    static CreateCollection(collection: string): DivaCollection {
        let item = new DivaCollection();
        item.collection = collection;
        item.folder = nconf.get("paths:filesPath") + path.sep + collection + path.sep;
        item.url = "http://" + nconf.get("server:rootUrl") + "/collections/" + collection;
        item.zipUrl = "http://" + nconf.get("server:rootUrl") + "/collections/" + collection + "/zip";
        return item;
    }

    /**
     * Create a DivaCollection from the full path to the collection 
     * THIS METHOD IS ONLY USED IN THE TESTING PROCESS OF A METHOD
     * 
     * @static
     * @param {string} filePath The full path to the collection
     * @returns {DivaCollection} The created DivaCollection
     * @memberof DivaCollection
     */
    static CreateCollectionFull(filePath: string): DivaCollection {
        let relativePath = filePath.replace(nconf.get("paths:executablePath") + path.sep, "");
        let item = new DivaCollection();
        item.collection = "";
        item.folder = filePath;
        item.url = "http://" + nconf.get("server:rootUrl") + "/test/" + relativePath;
        item.zipUrl = "http://" + nconf.get("server:rootUrl") + "/test/" + relativePath;
        return item;
    }

}