import * as core from '@actions/core';
import * as github from '@actions/github';
import { buildGreeting, parseStyle } from './greeting.js';

// Ch3 "Creating a TypeScript action": read inputs, write outputs, annotate, summarise.
export async function run(): Promise<void> {
  try {
    const who = core.getInput('who-to-greet', { required: true });
    const style = parseStyle(core.getInput('style'));
    const greeting = buildGreeting(who, style);
    const time = new Date().toISOString();

    core.info(greeting);
    core.debug(`style=${style}`); // only shown with debug logging (Ch2)
    core.setOutput('greeting', greeting);
    core.setOutput('time', time);

    const { eventName, actor, repo, sha } = github.context;
    await core.summary
      .addHeading('TypeScript action', 3)
      .addTable([
        [
          { data: 'Field', header: true },
          { data: 'Value', header: true },
        ],
        ['greeting', greeting],
        ['event', eventName],
        ['actor', actor],
        ['repository', `${repo.owner}/${repo.repo}`],
        ['commit', sha.substring(0, 7)],
        ['time', time],
      ])
      .write();
  } catch (error) {
    core.setFailed(error instanceof Error ? error.message : String(error));
  }
}
