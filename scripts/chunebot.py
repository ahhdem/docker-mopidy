import discord
from discord.ext import commands
import random
import subprocess

description = '''An example bot to showcase the discord.ext.commands extension
module.

There are a number of utility commands being showcased here.'''
bot = commands.Bot(command_prefix='?', description=description)

def now_playing():
    return track_path(subprocess.run(['/bin/cat', '/config/now-playing'], capture_output=True, text=True).stdout)


def track_path(path):
    path_bits=path.split('/')
    return '%s/%s' % (path_bits[-2], path_bits[-1])


def skip():
    skipped=now_playing()
    current=skipped
    subprocess.run(['/next', 'ezstream'])
    while current == skipped:
        current = now_playing()

    return (skipped, current)


@bot.event
async def on_ready():
    print('Logged in as %s (uid: %d)' % (bot.user.name, bot.user.id))


@bot.command()
async def next(ctx):
    """Skips radio song (there is no back!)"""
    await ctx.send('Skipped %s - Now playing: %s' % skip())


@bot.command()
async def playing(ctx):
    """Skips radio song (there is no back!)"""
    await ctx.send('Now playing: %s' % (now_playing()))


@bot.command()
async def prev(ctx):
    """Plays previous radio song (there is no back!)"""
    subprocess.run(['cp','/config/now-playing','/config/next'])
    await ctx.send('Skipped %s - Now playing: %s' % skip())


bot.run('CHUNEBOT_TOKEN')
