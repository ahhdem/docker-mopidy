#!/usr/bin/python3

import discord
from discord.ext import commands
import random
import subprocess

description = '''An example bot to showcase the discord.ext.commands extension
module.

There are a number of utility commands being showcased here.'''
bot = commands.Bot(command_prefix='?', description=description)

def now_playing():
    current = ''
    while current == '':
        current = subprocess.run(['/bin/cat', '/config/now-playing'], capture_output=True, text=True).stdout

    path_bits=current.split('/')
    return '%s/%s' % (path_bits[-2], path_bits[-1])


async def skip(to=''):
    if (to):
       await copynext(to)
    skipped=now_playing()
    current=skipped
    subprocess.run(['/next', 'ezstream'])
    if (to == 'now-playing'):
        # Dont wait for a different song if restarting track
        return (skipped, current)
    while current == skipped:
        current = now_playing()

    return (skipped, current)


async def copynext(track):
    subprocess.run(['cp','/config/%s' % track, '/config/next'])
    return True

@bot.event
async def on_ready():
    print('Logged in as %s (uid: %d)' % (bot.user.name, bot.user.id))


@bot.command()
async def next(ctx):
    """Skips to next song"""
    print("Skipping track")
    await ctx.send('Skipped %s - Now playing: %s' % await skip())


@bot.command()
async def playing(ctx):
    """Show currently playing track"""
    await ctx.send('Now playing: %s' % (now_playing()))


@bot.command()
async def back(ctx):
    """Restarts current radio song"""
    print("Restarting track")
    (skipped, current) = await skip('now-playing')
    await ctx.send('Restarting: %s' % current)


@bot.command()
async def prev(ctx):
    """Restarts current radio song (there is no back!)"""
    print("Playing previous track")
    await ctx.send('Skipped %s - Now playing: %s' % await skip('previous'))


bot.run('CHUNEBOT_TOKEN')
