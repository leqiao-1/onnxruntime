// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

import {execSync, spawnSync} from 'child_process';
import * as fs from 'fs-extra';
import npmlog from 'npmlog';
import * as path from 'path';

// Path variables
const WASM_JS_PATH = path.join(__dirname, '..', 'lib', 'wasm', 'binding', 'onnxruntime_wasm.js');
const WASM_PATH = path.join(__dirname, '..', 'lib', 'wasm', 'binding', 'onnxruntime_wasm.wasm');
const WASM_DIST_PATH = path.join(__dirname, '..', 'dist', 'onnxruntime_wasm.wasm');

try {
  npmlog.info('Build', `Ensure file: ${WASM_JS_PATH}`);
  fs.ensureFileSync(WASM_JS_PATH);
  npmlog.info('Build', `Ensure file: ${WASM_PATH}`);
  fs.ensureFileSync(WASM_PATH);
} catch (e) {
  npmlog.error('Build', `WebAssembly files are not ready. build WASM first. ERR: ${e}`);
  throw e;
}

npmlog.info('Build', `Copying file "${WASM_PATH}" to "${WASM_DIST_PATH}"...`);
fs.copyFileSync(WASM_PATH, WASM_DIST_PATH);

npmlog.info('Build', 'Building bundle...');
{
  npmlog.info('Build.Bundle', '(1/2) Retrieving npm bin folder...');
  const npmBin = execSync('npm bin', {encoding: 'utf8'}).trimRight();
  npmlog.info('Build.Bundle', `(1/2) Retrieving npm bin folder... DONE, folder: ${npmBin}`);

  npmlog.info('Build.Bundle', '(2/2) Running webpack to generate bundles...');
  const webpackCommand = path.join(npmBin, 'webpack');
  const webpackArgs: string[] = [];
  npmlog.info('Build.Bundle', `CMD: ${webpackCommand} ${webpackArgs.join(' ')}`);
  const webpack = spawnSync(webpackCommand, webpackArgs, {shell: true, stdio: 'inherit'});
  if (webpack.status !== 0) {
    console.error(webpack.error);
    process.exit(webpack.status === null ? undefined : webpack.status);
  }
  npmlog.info('Build.Bundle', '(2/2) Running webpack to generate bundles... DONE');
}
npmlog.info('Build', 'Building bundle... DONE');
