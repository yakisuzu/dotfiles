#!/usr/bin/env node

const fs = require('fs');
const { spawnSync } = require('child_process');
const os = require('os');
const path = require('path');

// デバッグログファイル
const logFile = path.join(os.homedir(), 'claude_hook_debug.log');
const log = (msg) => {
  const timestamp = new Date().toISOString();
  fs.appendFileSync(logFile, `[${timestamp}] ${msg}\n`);
};

log('=== Hook script started ===');

// stdin からJSONを読み取る
let inputData = '';
process.stdin.on('data', (chunk) => {
  inputData += chunk;
  log(`Received data chunk: ${chunk.length} bytes`);
});

process.stdin.on('end', () => {
  try {
    log(`Total input data: ${inputData.length} bytes`);
    const input = JSON.parse(inputData);
    log(`Parsed input JSON: ${JSON.stringify(input, null, 2)}`);

    // transcript_path を取得
    const transcriptPath = input.transcript_path;
    if (!transcriptPath) {
      log('ERROR: transcript_path not found in input');
      console.error('transcript_path not found in input');
      process.exit(1);
    }
    log(`transcript_path: ${transcriptPath}`);

    // チルダを展開
    const expandedPath = transcriptPath.replace(/^~/, process.env.HOME);
    log(`Expanded path: ${expandedPath}`);

    // JSONLファイルを読み込み
    if (!fs.existsSync(expandedPath)) {
      log(`ERROR: Transcript file not found: ${expandedPath}`);
      console.error(`Transcript file not found: ${expandedPath}`);
      process.exit(1);
    }

    const content = fs.readFileSync(expandedPath, 'utf-8');
    log(`Read transcript file: ${content.length} bytes`);
    const lines = content.trim().split('\n').filter(line => line.length > 0);
    log(`Total lines: ${lines.length}`);

    // 最後のassistantメッセージを探す
    let lastAssistantText = '';
    log('Searching for assistant messages...');

    for (let i = lines.length - 1; i >= 0; i--) {
      try {
        const entry = JSON.parse(lines[i]);

        // message オブジェクトをチェック
        if (entry.message && entry.message.role === 'assistant' && Array.isArray(entry.message.content)) {
          log(`Found assistant message at line ${i}, content items: ${entry.message.content.length}`);
          // content配列からtype: "text"のものを抽出
          for (const item of entry.message.content) {
            log(`  Content item type: ${item.type}`);
            if (item.type === 'text' && item.text) {
              lastAssistantText = item.text;
              log(`  Found text content: ${item.text.substring(0, 100)}...`);
              break;
            }
          }

          if (lastAssistantText) {
            break;
          }
        }
      } catch (e) {
        // JSONパースエラーは無視して次の行へ
        continue;
      }
    }

    log(`Last assistant text found: ${lastAssistantText ? 'YES' : 'NO'} (length: ${lastAssistantText.length})`);

    // テキストが見つかった場合はsayで読み上げ
    if (lastAssistantText) {
      log('Processing text for speech...');
      // マークダウン記法やコードブロックを簡易的に除去
      let cleanText = lastAssistantText
        .replace(/```[\s\S]*?```/g, 'コードブロック省略')
        .replace(/`[^`]+`/g, '')
        .replace(/\[([^\]]+)\]\([^\)]+\)/g, '$1')
        .replace(/[#*_~]/g, '')
        .trim();

      log(`Cleaned text length: ${cleanText.length}`);

      // 長すぎる場合は最初の部分だけ
      const maxLength = 500;
      if (cleanText.length > maxLength) {
        cleanText = cleanText.substring(0, maxLength) + '...以下省略';
        log('Text truncated to 500 characters');
      }

      if (cleanText.length > 0) {
        // 環境変数でvoicevoxを使うか判定
        const useVoicevox = process.env.CLAUDE_USE_VOICEVOX === 'true';
        const command = useVoicevox ? path.join(__dirname, 'voicevox') : 'say';

        log(`Executing ${command} command with text: ${cleanText.substring(0, 50)}...`);
        const result = spawnSync(command, [cleanText], { stdio: 'inherit' });
        log(`${command} command exit code: ${result.status}`);
        if (result.error) {
          log(`${command} command error: ${result.error.message}`);
        }
      } else {
        log('Clean text is empty, skipping speech command');
      }
    } else {
      log('No assistant text found, skipping say command');
    }

    log('=== Hook script completed successfully ===');

  } catch (error) {
    log(`ERROR: ${error.message}`);
    log(`Stack trace: ${error.stack}`);
    console.error('Error processing transcript:', error.message);
    process.exit(1);
  }
});

// エラーハンドリング
process.stdin.on('error', (error) => {
  log(`ERROR reading stdin: ${error.message}`);
  console.error('Error reading stdin:', error.message);
  process.exit(1);
});
