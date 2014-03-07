/*
 * Copyright Teoken LLC. (c) 2013. All rights reserved.
 * Copying or usage of any piece of this source code without written notice from Teoken LLC is a major crime.
 * Այս կոդը Թեոկեն ՍՊԸ ընկերության սեփականությունն է:
 * Առանց գրավոր թույլտվության այս կոդի պատճենահանումը կամ օգտագործումը քրեական հանցագործություն է:
 */

/**
 * User: sarg
 * Date: 4/12/12
 * Time: 9:01 PM
 */
package saltr.parser {
import flash.utils.Dictionary;

import saltr.parser.data.SLTVector2D;
import saltr.parser.gameeditor.SLTBoardData;
import saltr.parser.gameeditor.SLTCell;
import saltr.parser.gameeditor.chunk.SLTAssetInChunk;
import saltr.parser.gameeditor.chunk.SLTChunk;
import saltr.parser.gameeditor.composite.SLTComposite;
import saltr.parser.gameeditor.composite.SLTCompositeAsset;
import saltr.parser.gameeditor.SLTAsset;

final public class SLTLevelParser {

    public static function parseBoard(outputBoard:SLTVector2D, rawBoard:Object, boardData:SLTBoardData):void {
        createEmptyBoard(outputBoard, rawBoard);
        var composites:Dictionary = parseComposites(rawBoard.composites as Array, outputBoard, boardData);
        var boardChunks:Dictionary = parseChunks(rawBoard.chunks as Array, outputBoard, boardData);
        generateComposites(composites);
        generateChunks(boardChunks);
    }

    public static function regenerateChunks(outputBoard:SLTVector2D, board:Object, boardData:SLTBoardData):void {
        var boardChunks:Dictionary = parseChunks(board.chunks as Array, outputBoard, boardData);
        generateChunks(boardChunks);
    }

    private static function generateChunks(chunks:Dictionary):void {
        for (var key:Object in chunks) {
            (chunks[key] as SLTChunk).generate();
        }
    }

    private static function generateComposites(composites:Dictionary):void {
        for (var key:Object in composites) {
            (composites[key] as SLTComposite).generate();
        }
    }

    private static function createEmptyBoard(board:SLTVector2D, rawBoard : Object):void {
        var blockedCells : Array = rawBoard.hasOwnProperty("blockedCells") ? rawBoard.blockedCells : [];
        var cellProperties : Array = rawBoard.hasOwnProperty("properties") && rawBoard.properties.hasOwnProperty("cell") ? rawBoard.properties.cell : [];
        var cols:int = board.width;
        var rows:int = board.height;
        for (var i:int = 0; i < rows; ++i) {
            for (var j:int = 0; j < cols; ++j) {
                var cell : SLTCell = new SLTCell(j,i);
                board.insert(j, i, cell);
                for(var p : int = 0; p < cellProperties.length; p++) {
                    var property : Object = cellProperties[p];
                    if(property.coords[0] == j && property.coords[1] == i) {
                        cell.properties = property.value;
                        break;
                    }
                }
                for(var b : int = 0; b < blockedCells.length; b++) {
                    var blockedCell : Array = blockedCells[b];
                    if(blockedCell[0] == j && blockedCell[1] == i) {
                        cell.isBlocked = true;
                        break;
                    }
                }
            }
        }
    }

    private static function parseChunks(chunksPrototype:Array, outputBoard:SLTVector2D, boardData:SLTBoardData):Dictionary {
        var chunks:Dictionary = new Dictionary();
        for each (var chunkPrototype:* in chunksPrototype) {
            var chunk : SLTChunk = new SLTChunk(String(chunkPrototype.chunkId), boardData);
            var assetsPrototype:Array = chunkPrototype.assets as Array;
            for each (var assetPrototype:* in assetsPrototype) {
                var chunkAsset:SLTAssetInChunk = new SLTAssetInChunk(assetPrototype.assetId, assetPrototype.count, assetPrototype.stateId);
                chunk.addChunkAsset(chunkAsset);
            }
            var cellsPrototype:Array = chunkPrototype.cells as Array;
            for each(var cellPrototype:* in cellsPrototype) {
                chunk.addCell(outputBoard.retrieve(cellPrototype[0], cellPrototype[1]) as SLTCell);
            }
            chunks[chunk.id] = chunk;
        }
        return chunks;
    }

    private static function parseComposites(composites:Array, outputBoard:SLTVector2D, boardData:SLTBoardData):Dictionary {
        var compositesMap:Dictionary = new Dictionary();
        for each(var compositePrototype:* in composites) {
            var composite:SLTComposite = new SLTComposite(compositePrototype.assetId, outputBoard.retrieve(compositePrototype.position[0], compositePrototype.position[1]) as SLTCell, boardData);
            compositesMap[composite.id] = composite;
        }
        return compositesMap;
    }

    public static function parseBoardData(data:Object):SLTBoardData {
        var boardData:SLTBoardData = new SLTBoardData();
        boardData.assetMap = parseBoardAssets(data["assets"]);
        boardData.keyset = data["keySets"];
        boardData.stateMap = parseAssetStates(data["assetStates"]);
        return boardData;
    }

    private static function parseAssetStates(states:Object):Dictionary {
        var statesMap:Dictionary = new Dictionary();
        for (var object:Object in states) {
            //noinspection JSUnfilteredForInLoop
            statesMap[object] = states[object];
        }
        return statesMap;
    }

    private static function parseBoardAssets(assets:Object):Dictionary {
        var assetMap:Dictionary = new Dictionary();
        for (var object:Object in assets) {
            //noinspection JSUnfilteredForInLoop
            assetMap[object] = parseAsset(assets[object]);
        }
        return assetMap;

    }

    private static function parseAsset(asset:Object):SLTAsset {
        if (asset.cells/*if asset is composite asset*/) {
            return new SLTCompositeAsset(asset.cells as Array, asset.type_key, asset.keys);
        }
        return new SLTAsset(asset.type_key, asset.keys);
    }
}
}