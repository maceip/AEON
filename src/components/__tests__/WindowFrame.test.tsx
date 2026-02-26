import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { WindowFrame } from '../WindowFrame';
import React from 'react';
import '@testing-library/jest-dom';

// Mock dnd-kit
vi.mock('@dnd-kit/sortable', () => ({
  useSortable: () => ({
    attributes: {},
    listeners: {},
    setNodeRef: () => {},
    transform: null,
    transition: null,
    isDragging: false,
  }),
  SortableContext: ({ children }: any) => <div>{children}</div>,
  rectSortingStrategy: {},
}));

describe('WindowFrame', () => {
  const props = {
    id: 'test-frame',
    title: 'Test Window',
    onClose: vi.fn(),
    onMinimize: vi.fn(),
    onMaximize: vi.fn(),
    onRestore: vi.fn(),
    onShare: vi.fn(),
    onPopout: vi.fn(),
    onTogglePause: vi.fn(),
    isMaximized: false,
    isMinimized: false,
    isPoppedOut: false,
    isPaused: false,
  };

  it('renders title and controls', () => {
    render(<WindowFrame {...props}><div>Content</div></WindowFrame>);
    expect(screen.getByText('Test Window')).toBeTruthy();
    expect(screen.getByText('Content')).toBeTruthy();
  });

  it('calls minimize when button clicked', () => {
    render(<WindowFrame {...props}><div>Content</div></WindowFrame>);
    const minBtn = screen.getByRole('button', { name: /Minimize/i });
    fireEvent.click(minBtn);
    expect(props.onMinimize).toHaveBeenCalled();
  });

  it('calls maximize when button clicked', () => {
    render(<WindowFrame {...props}><div>Content</div></WindowFrame>);
    const maxBtn = screen.getByRole('button', { name: /Maximize/i });
    fireEvent.click(maxBtn);
    expect(props.onMaximize).toHaveBeenCalled();
  });

  it('calls close when button clicked', () => {
    render(<WindowFrame {...props}><div>Content</div></WindowFrame>);
    const closeBtn = screen.getByRole('button', { name: /Close/i });
    fireEvent.click(closeBtn);
    expect(props.onClose).toHaveBeenCalled();
  });

  it('calls restore when button clicked', () => {
    render(<WindowFrame {...props}><div>Content</div></WindowFrame>);
    const restoreBtn = screen.getByRole('button', { name: /Restore Window/i });
    fireEvent.click(restoreBtn);
    expect(props.onRestore).toHaveBeenCalled();
  });

  it('calls popout when button clicked', () => {
    render(<WindowFrame {...props}><div>Content</div></WindowFrame>);
    const popoutBtn = screen.getByRole('button', { name: /Pop Out/i });
    fireEvent.click(popoutBtn);
    expect(props.onPopout).toHaveBeenCalled();
  });

  it('calls toggle pause when button clicked', () => {
    render(<WindowFrame {...props}><div>Content</div></WindowFrame>);
    const pauseBtn = screen.getByRole('button', { name: /Pause and Snapshot/i });
    fireEvent.click(pauseBtn);
    expect(props.onTogglePause).toHaveBeenCalled();
  });

  it('renders correct label for paused state', () => {
    render(<WindowFrame {...props} isPaused={true}><div>Content</div></WindowFrame>);
    expect(screen.getByRole('button', { name: /Resume Session/i })).toBeTruthy();
  });

  it('hides content when minimized', () => {
    render(<WindowFrame {...props} isMinimized={true}><div>HiddenContent</div></WindowFrame>);
    // Content is wrapped in a div with 'hidden' class
    const content = screen.getByText('HiddenContent');
    expect(content.parentElement).toHaveClass('hidden');
  });
});
