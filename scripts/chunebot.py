#!/usr/bin/python3

import discord
from discord.ext import commands
from subprocess import run
from urllib import request
from xmltodict import parse as xmlparse

description = '''An example bot to showcase the discord.ext.commands extension
module.

There are a number of utility commands being showcased here.'''
bot = commands.Bot(command_prefix='?', description=description)

async def findStream(stream):
    url = 'http://icecast:8000/%s.xspf' % stream
    file = request.urlopen(url)
    data = file.read()
    file.close()

    data = xmlparse(data)
    stats = data['playlist']['trackList']['track']
    stats['stream'] =  stream

    return stats if stats['title'] else None


async def getStreamStatus():
    streams = ['live', 'radio']
    for stream in streams:
        details = await findStream(stream)
        if details:
            break;

    a_list = [ stat for stat in details['annotation'].split('\n')]
    for stat in a_list:
        s = stat.split(':')
        details[s[0]] = s[1]

    return details


def nowPlaying():
    current = ''
    while current is '':
        current = run(['/bin/cat', '/config/now-playing'], capture_output=True, text=True).stdout

    path_bits=current.split('/')
    return path_bits[5:].join('/')


async def skipTo(song='', stream='ezstream'):
    if (song):
       await setNextTrack(song)
    skipped=nowPlaying()
    current=skipped
    run(['/next', stream])
    if (song is 'now-playing'):
        # Dont wait for song change if restarting
        return (skipped, current)
    # Wait for the song to change
    while current == skipped:
        current = nowPlaying()

    return (skipped, current)


async def setNextTrack(track):
    run(['cp','/config/%s' % track, '/config/next'])
    return True

@bot.event
async def on_ready():
    print('Logged in as %s (uid: %d)' % (bot.user.name, bot.user.id))


@bot.command()
async def next(ctx):
    """Skips to next song"""
    print("Skipping track")
    await ctx.send('Skipped %s - Now playing: %s' % await skipTo())


@bot.command()
async def playing(ctx):
    """Show currently playing track"""
    await ctx.send('Now playing: %s' % (nowPlaying()))


@bot.command()
async def back(ctx):
    """Restarts current radio song"""
    print("Restarting track")
    (skipped, current) = await skipTo('now-playing')
    await ctx.send('Restarting: %s' % current)


@bot.command()
async def prev(ctx):
    """Restarts current radio song (there is no back!)"""
    print("Playing previous track")
    await ctx.send('Skipped %s - Now playing: %s' % await skipTo('previous'))

@bot.command()
async def stats(ctx):
    """Gets current stream stats"""
    print("Fetching stats")
    status = await getStreamStatus()
    msg = 'https://ICECAST_HOST/{stream}\nNow Playing: {creator} - {title}\nListeners: {listeners}\nQuality: {bitrate}kbps'.format(
            stream=status['stream'],
            creator=status['creator'],
            title=status['title'],
            listeners=status['Current Listeners'],
            bitrate=status['Bitrate'])

    await ctx.send(msg)


bot.run('CHUNEBOT_TOKEN')
