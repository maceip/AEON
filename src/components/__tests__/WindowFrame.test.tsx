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
    onPopout: vi.fn(), // Added onPopout mock
    onTogglePause: vi.fn(), // Added onTogglePause mock
    isMaximized: false,
    isMinimized: false,
    isPoppedOut: false,
    isPaused: false,
  };

  it('renders title and content', () => {
    render(<WindowFrame {...props}><div>Content</div></WindowFrame>);
    expect(screen.getByText('Test Window')).toBeTruthy();
    expect(screen.getByText('Content')).toBeTruthy();
  });

  it('renders control buttons with accessible names', () => {
    render(<WindowFrame {...props}><div>Content</div></WindowFrame>);

    // Verify all buttons are findable by their accessible name (aria-label)
    expect(screen.getByRole('button', { name: /minimize/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /maximize/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /close/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /restore window/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /pop out/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /pause & snapshot/i })).toBeInTheDocument();
  });

  it('updates aria-label when state changes (maximize/restore)', () => {
    const { rerender } = render(<WindowFrame {...props} isMaximized={false}><div>Content</div></WindowFrame>);
    expect(screen.getByRole('button', { name: /maximize/i })).toBeInTheDocument();

    rerender(<WindowFrame {...props} isMaximized={true}><div>Content</div></WindowFrame>);
    expect(screen.getByRole('button', { name: /restore down/i })).toBeInTheDocument();
  });

  it('updates aria-label when state changes (popout)', () => {
    const { rerender } = render(<WindowFrame {...props} isPoppedOut={false}><div>Content</div></WindowFrame>);
    expect(screen.getByRole('button', { name: /pop out/i })).toBeInTheDocument();

    rerender(<WindowFrame {...props} isPoppedOut={true}><div>Content</div></WindowFrame>);
    expect(screen.getByRole('button', { name: /pop in/i })).toBeInTheDocument();
  });

  it('updates aria-label when state changes (pause/resume)', () => {
    const { rerender } = render(<WindowFrame {...props} isPaused={false}><div>Content</div></WindowFrame>);
    expect(screen.getByRole('button', { name: /pause & snapshot/i })).toBeInTheDocument();

    rerender(<WindowFrame {...props} isPaused={true}><div>Content</div></WindowFrame>);
    expect(screen.getByRole('button', { name: /resume session/i })).toBeInTheDocument();
  });

  it('calls minimize when button clicked', () => {
    render(<WindowFrame {...props}><div>Content</div></WindowFrame>);
    const minBtn = screen.getByRole('button', { name: /minimize/i });
    fireEvent.click(minBtn);
    expect(props.onMinimize).toHaveBeenCalled();
  });

  it('calls maximize when button clicked', () => {
    render(<WindowFrame {...props}><div>Content</div></WindowFrame>);
    const maxBtn = screen.getByRole('button', { name: /maximize/i });
    fireEvent.click(maxBtn);
    expect(props.onMaximize).toHaveBeenCalled();
  });

  it('hides content when minimized', () => {
    render(<WindowFrame {...props} isMinimized={true}><div>HiddenContent</div></WindowFrame>);
    // Content is wrapped in a div with 'hidden' class
    const content = screen.getByText('HiddenContent');
    expect(content.parentElement).toHaveClass('hidden');
  });
});
