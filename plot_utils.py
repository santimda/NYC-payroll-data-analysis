import matplotlib

# Define nice plot settings using LaTeX fonts
nice_fonts = {
    "text.usetex": True,
    "font.family": 'serif',
    "axes.labelsize": 18,
    "font.size": 20,
    "axes.linewidth": 1.5,
    "axes.titlesize": 20,
    "legend.fontsize": 14,
    # Ticks settings
    "xtick.labelsize": 16,
    "ytick.labelsize": 16,
    "xtick.major.size": 5.5,  
    "xtick.minor.size": 4,    
    "ytick.major.size": 5.5,  
    "ytick.minor.size": 3.5,  
    "xtick.major.width": 1.4,  
    "xtick.minor.width": 1.3,  
    "ytick.major.width": 1.4,  
    "ytick.minor.width": 1.3,              
    "xtick.direction": "in",
    "ytick.direction": "in",
    "xtick.top": True,
    "ytick.right": True,
}

matplotlib.rcParams.update(nice_fonts)